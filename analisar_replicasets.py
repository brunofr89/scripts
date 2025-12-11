#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
analisar_replicasets_full.py

- Versão final: coleta logs de até 3 ReplicaSets (pod por pod) usando kubeconfig direto.
- Análise paralela (threads), extração de evidências e export para TXT/MD.
- Ajuste ALIAS_MAP para seus kubeconfigs localmente se necessário.
"""

import subprocess
import re
import sys
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path
from textwrap import indent

# ----------------------------
# CONFIGURAÇÃO (edite conforme seu ambiente)
# ----------------------------
# Mapeamento alias -> caminho do kubeconfig (substitua pelos seus caminhos exatos)
ALIAS_MAP = {
    "kocta-dev-us-east5-001": "/home/brunorodrigues/.kube/kubeconfig/config-octa-dev-us-east5-001",
    "kocta-qa-us-east1-001": "/home/brunorodrigues/.kube/kubeconfig/config-octa-qa-us-east1-001",
    "kocta-pantheon-sa-east1-001": "/home/brunorodrigues/.kube/kubeconfig/config-octa-pantheon-sa-east1-001",
    "kocta-prod-sa-east1-004": "/home/brunorodrigues/.kube/kubeconfig/config-octa-prod-sa-east1-004",
    "kocta-prod-us-east1-001": "/home/brunorodrigues/.kube/kubeconfig/config-octa-prod-us-east1-001",
    "kocta-prod-us-east1-beta": "/home/brunorodrigues/.kube/kubeconfig/config-octa-prod-us-east1-beta",
    "kocta-prod-sa-east1-003": "/home/brunorodrigues/.kube/kubeconfig/config-octa-prod-sa-east1-003",
    "kocta-prod-southameri-east1-001": "/home/brunorodrigues/.kube/kubeconfig/config-octa-prod-southameri-east1-001",
}

# Quantidade de linhas a coletar por pod (escolheu 200)
TAIL_LINES = 200

# Quantidade máxima de evidências (trechos) por pod que aparecerão no relatório
MAX_EVIDENCES_PER_POD = 2

# Diretório onde relatórios serão salvos
REPORT_DIR = Path("./relatorios")
REPORT_DIR.mkdir(parents=True, exist_ok=True)

# Cores discretas ANSI (usadas no terminal)
class C:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    RED = "\033[31m"
    CYAN = "\033[36m"
    MAGENTA = "\033[35m"

# Detecta se terminal suporta cores (simples)
def supports_color():
    return sys.stdout.isatty()

USE_COLOR = supports_color()

def color(text, code):
    if USE_COLOR:
        return f"{code}{text}{C.RESET}"
    return text

# ----------------------------
# Padrões de detecção (regex)
# ----------------------------
ERROR_PATTERNS = re.compile(
    r"(too many connections|pool.*exhausted|max.?pool|pool is full|could not acquire connection|"
    r"timeout acquiring connection|MongoTimeoutError|MongoNetworkError|MongoServerError|"
    r"connection refused|ECONN|ECONNREFUSED|ECONNRESET|socket hang up|socket error|"
    r"Exception|Error|5\d\d|SQL.*timeout|database.*timeout|timed out)",
    re.IGNORECASE,
)

CAUSE_PATTERNS = {
    "POOL_EXHAUSTION": re.compile(r"(too many connections|pool.*exhausted|max.?pool|pool is full|could not acquire connection|timeout acquiring connection)", re.IGNORECASE),
    "TIMEOUT_DB": re.compile(r"(MongoTimeoutError|SQL.*timeout|database.*timeout|timed out)", re.IGNORECASE),
    "CONN_ERRORS": re.compile(r"(connection refused|ECONN|ECONNREFUSED|ECONNRESET|socket hang up|socket error|MongoNetworkError)", re.IGNORECASE),
    "HTTP_5XX": re.compile(r"\b5\d\d\b"),
    "EXCEPTION": re.compile(r"\bException\b|\bError\b", re.IGNORECASE),
}

# ----------------------------
# Helpers para executar kubectl com kubeconfig
# ----------------------------
def run_cmd(cmd):
    """Executa comando shell e retorna stdout (str). Em caso de erro, retorna stderr/text."""
    try:
        out = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, text=True)
        return out
    except subprocess.CalledProcessError as e:
        return e.output or ""

def kube_get_pods(kubeconfig, namespace, prefix):
    cmd = f'kubectl --kubeconfig "{kubeconfig}" -n {namespace} get pods --no-headers'
    out = run_cmd(cmd)
    pods = []
    for line in out.splitlines():
        parts = line.split()
        if parts and parts[0].startswith(prefix):
            pods.append(parts[0])
    return pods

def kube_logs_tail(kubeconfig, namespace, pod, tail=TAIL_LINES):
    cmd = f'kubectl --kubeconfig "{kubeconfig}" -n {namespace} logs {pod} --tail={tail}'
    return run_cmd(cmd)

# ----------------------------
# Análise de logs / extração de evidências
# ----------------------------
def analyze_log_text(log_text):
    """Retorna lista de causas detectadas (lista de strings).
       Também retorna 'evidence_lines' — até MAX_EVIDENCES_PER_POD trechos (com contexto)."""
    causes = set()
    evidence_snippets = []

    if not log_text:
        return [], []

    lines = log_text.splitlines()

    # procura linhas que batem com ERROR_PATTERNS
    matches_idx = []
    for idx, line in enumerate(lines):
        if ERROR_PATTERNS.search(line):
            matches_idx.append(idx)

    # extrair causas
    for name, pattern in CAUSE_PATTERNS.items():
        if pattern.search(log_text):
            causes.add(name)

    # coletar até MAX_EVIDENCES_PER_POD trechos com uma linha de contexto acima/abaixo quando possível
    picked = 0
    used_idx = set()
    for idx in matches_idx:
        if picked >= MAX_EVIDENCES_PER_POD:
            break
        if idx in used_idx:
            continue
        start = max(0, idx - 1)
        end = min(len(lines) - 1, idx + 1)
        snippet = "\n".join(lines[start:end+1])
        evidence_snippets.append(snippet)
        used_idx.update(range(start, end+1))
        picked += 1

    return sorted(list(causes)), evidence_snippets

# ----------------------------
# Função worker que processa um pod
# ----------------------------
def process_pod(kubeconfig, namespace, pod):
    logs = kube_logs_tail(kubeconfig, namespace, pod, tail=TAIL_LINES)
    causes, evidences = analyze_log_text(logs)
    # construir resumo curto
    if not causes:
        summary = "OK"
    else:
        summary = ", ".join(causes)
    return {
        "pod": pod,
        "summary": summary,
        "causes": causes,
        "evidences": evidences,
        "raw_logs_present": bool(logs.strip())
    }

# ----------------------------
# Entrada interativa (até 3 replicasets)
# ----------------------------
def collect_replicasets_input():
    replicasets = []
    for i in range(1, 4):
        add = input(f"Deseja adicionar o replicaset {i}? (s/n): ").strip().lower()
        if add != "s":
            break
        cluster_alias = input("Informe o alias do cluster (conforme ALIAS_MAP): ").strip()
        if cluster_alias not in ALIAS_MAP:
            print(color(f"[ERRO] Alias '{cluster_alias}' não está em ALIAS_MAP. Atualize o script.", C.RED))
            sys.exit(1)
        kubeconfig = ALIAS_MAP[cluster_alias]
        namespace = input("Informe o namespace: ").strip()
        prefix = input("Informe o prefixo do replicaset: ").strip()
        replicasets.append({
            "alias": cluster_alias,
            "kubeconfig": kubeconfig,
            "namespace": namespace,
            "prefix": prefix
        })
    if not replicasets:
        print(color("Nenhum replicaset informado. Abortando.", C.YELLOW))
        sys.exit(0)
    return replicasets

# ----------------------------
# Relatório / formatação
# ----------------------------
def format_pod_result(pod_result):
    pod = pod_result["pod"]
    summary = pod_result["summary"]
    if summary == "OK":
        return color(f"• Pod {pod}: Nenhuma anomalia identificada", C.GREEN)
    else:
        return color(f"• Pod {pod}: {summary}", C.YELLOW)

def build_report(replicaset_results):
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    title = f"Análise – Excesso de conexões / instabilidade - {now}"
    lines = []
    lines.append(title)
    lines.append("=" * len(title))
    lines.append("")
    for rp in replicaset_results:
        header = f"ReplicaSet: {rp['prefix']} (cluster alias: {rp['alias']}, namespace: {rp['namespace']})"
        lines.append(header)
        lines.append("-" * len(header))
        for pod_result in rp["pods"]:
            pod = pod_result["pod"]
            lines.append(f"Pod: {pod}")
            lines.append(f"Resumo: {pod_result['summary']}")
            if pod_result["causes"]:
                lines.append("Causas detectadas: " + ", ".join(pod_result["causes"]))
            else:
                lines.append("Causas detectadas: Nenhuma")
            if pod_result["evidences"]:
                lines.append("Evidências (trechos):")
                for ev in pod_result["evidences"]:
                    # identar a evidencia
                    lines.append(indent(ev.strip(), "    "))
                    lines.append("")  # espaço entre evidências
            lines.append("")  # espaço entre pods
        lines.append("")  # espaço entre replicasets

    # Conclusões inteligentes (agregadas)
    aggregated = []
    for rp in replicaset_results:
        for pod_result in rp["pods"]:
            aggregated.extend(pod_result["causes"])
    agg_set = set(aggregated)

    lines.append("CONCLUSÕES / RECOMENDAÇÕES")
    lines.append("-------------------------")
    if not agg_set:
        lines.append("- Não foram identificados erros, timeouts ou evidências de aumento de conexões nos logs recentes.")
        lines.append("- Recomenda-se monitoramento contínuo; se o alerta persistir, coletar métricas do Mongo/DB (connections, pool usage, wait queue).")
    else:
        if "POOL_EXHAUSTION" in agg_set:
            lines.append("- Detectado padrão de saturação de pool (POOL_EXHAUSTION). Possíveis causas:")
            lines.append("  • Aumento brusco de requisições (picos).")
            lines.append("  • Leak / criação de cliente por request em vez de singleton do driver.")
            lines.append("  • Consultas lentas no banco que mantêm conexões ocupadas.")
            lines.append("  Ações recomendadas: revisar poolSize, analisar slow queries, e validar criação/uso do cliente do driver.")
            lines.append("")
        if "TIMEOUT_DB" in agg_set:
            lines.append("- Identificados timeouts em operações de banco (TIMEOUT_DB). Verificar latência, índices e bloqueios.")
            lines.append("")
        if "CONN_ERRORS" in agg_set:
            lines.append("- Erros de conexão (CONN_ERRORS) detectados: verificar rede, endpoints do banco e disponibilidade de nós.")
            lines.append("")
        if "HTTP_5XX" in agg_set:
            lines.append("- Ocorrência de HTTP 5xx detectada; pode ser consequência direta dos erros acima.")
            lines.append("")
        if "EXCEPTION" in agg_set and not agg_set.intersection({"POOL_EXHAUSTION", "TIMEOUT_DB", "CONN_ERRORS"}):
            lines.append("- Foram observadas exceções genéricas; investigar stack traces e controllers específicos (ex.: /employees).")

    lines.append("")
    lines.append(f"Relatório gerado em {now}")
    return "\n".join(lines)

def save_reports(txt_content, md_content):
    ts = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    txt_path = REPORT_DIR / f"relatorio_{ts}.txt"
    md_path = REPORT_DIR / f"relatorio_{ts}.md"
    txt_path.write_text(txt_content, encoding="utf-8")
    md_path.write_text(md_content, encoding="utf-8")
    return txt_path, md_path

# ----------------------------
# Main
# ----------------------------
def main():
    replicasets = collect_replicasets_input()

    replicaset_results = []

    # paralelismo: por pod
    with ThreadPoolExecutor(max_workers=12) as executor:
        future_to_task = {}

        for rp in replicasets:
            kubeconfig = rp["kubeconfig"]
            namespace = rp["namespace"]
            prefix = rp["prefix"]
            alias = rp["alias"]

            pods = kube_get_pods(kubeconfig, namespace, prefix)
            if not pods:
                replicaset_results.append({
                    "alias": alias, "namespace": namespace, "prefix": prefix, "pods": [
                        {"pod": "Nenhum pod encontrado", "summary": "Nenhum pod encontrado", "causes": [], "evidences": []}
                    ]
                })
                continue

            # submit pod jobs
            rp_pod_futures = []
            for pod in pods:
                future = executor.submit(process_pod, kubeconfig, namespace, pod)
                future_to_task[future] = (alias, namespace, prefix, pod)
                rp_pod_futures.append(future)

            # collect futures for this replicaset
            rp_results = []
            for f in as_completed(rp_pod_futures):
                res = f.result()
                rp_results.append(res)

            # sort rp_results by pod name to keep deterministic output
            rp_results.sort(key=lambda x: x["pod"])
            replicaset_results.append({
                "alias": alias,
                "namespace": namespace,
                "prefix": prefix,
                "pods": rp_results
            })

    # build textual report
    report_text = build_report(replicaset_results)

    # build a markdown version: simply transform into md with code fences for evidences
    md_lines = []
    md_lines.append(f"# {report_text.splitlines()[0]}")
    md_lines.append("")
    # reuse same structure but present evidences as fenced code blocks
    for rp in replicaset_results:
        md_lines.append(f"## ReplicaSet: {rp['prefix']}  ")
        md_lines.append(f"- cluster alias: `{rp['alias']}`  ")
        md_lines.append(f"- namespace: `{rp['namespace']}`  ")
        md_lines.append("")
        for pod in rp["pods"]:
            md_lines.append(f"### Pod: `{pod['pod']}`")
            md_lines.append(f"- Resumo: `{pod['summary']}`")
            if pod["causes"]:
                md_lines.append(f"- Causas detectadas: {', '.join(pod['causes'])}")
            else:
                md_lines.append(f"- Causas detectadas: Nenhuma")
            if pod["evidences"]:
                md_lines.append("")
                md_lines.append("Trechos relevantes:")
                for ev in pod["evidences"]:
                    md_lines.append("```")
                    md_lines.append(ev.strip())
                    md_lines.append("```")
            md_lines.append("")

    # append conclusions section to md
    md_lines.append("## CONCLUSÕES / RECOMENDAÇÕES")
    md_lines.append("")
    aggregated = []
    for rp in replicaset_results:
        for pod in rp["pods"]:
            aggregated.extend(pod["causes"])
    agg_set = set(aggregated)
    if not agg_set:
        md_lines.append("- Não foram identificados erros, timeouts ou evidências de aumento de conexões nos logs recentes.")
    else:
        if "POOL_EXHAUSTION" in agg_set:
            md_lines.append("- Detectado padrão de saturação de pool (POOL_EXHAUSTION). Possíveis causas: aumento de carga, leak de conexões, queries lentas.")
        if "TIMEOUT_DB" in agg_set:
            md_lines.append("- Identificados timeouts em operações de banco (TIMEOUT_DB). Verificar latência e slow queries.")
        if "CONN_ERRORS" in agg_set:
            md_lines.append("- Erros de conexão detectados: verificar rede e disponibilidade de nós.")
        if "HTTP_5XX" in agg_set:
            md_lines.append("- Ocorrência de HTTP 5xx detectada; pode ser consequência direta das falhas de banco.")
    md_lines.append("")
    md_lines.append(f"_Relatório gerado em {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}_")

    md_content = "\n".join(md_lines)

    # Save reports
    txt_path, md_path = save_reports(report_text, md_content)

    # Print terminal-friendly output (colorized concise summary + evidence excerpts)

    # ---------------------------------------------------------------------------------------
    # RESUMO FINAL REFINADO (7 linhas, limpo, com resumo de causa e referência ao relatório)
    # ---------------------------------------------------------------------------------------

    print("\n" + color("===== RESUMO FINAL =====", C.BOLD))

    # Agregar causas detectadas em todos os pods
    all_causes = []
    for rp in replicaset_results:
        for pod in rp["pods"]:
            all_causes.extend(pod["causes"])

    unique_causes = set(all_causes)

    # Construir resumo curto
    if not unique_causes:
        resumo_curto = [
            "Nenhuma anomalia relevante foi identificada nos logs analisados.",
            "Não foram detectados timeouts, erros de conexão ou saturação de pool.",
            "O comportamento geral dos serviços está consistente com operação normal."
        ]
    else:
        resumo_curto = ["Foram identificados padrões relevantes nos logs:"]

        if "POOL_EXHAUSTION" in unique_causes:
            resumo_curto.append("- Evidências de saturação de pool de conexões.")
        if "TIMEOUT_DB" in unique_causes:
            resumo_curto.append("- Timeouts detectados em operações de banco de dados.")
        if "CONN_ERRORS" in unique_causes:
            resumo_curto.append("- Ocorrência de erros de conexão (rede, endpoint, disponibilidade).")
        if "HTTP_5XX" in unique_causes:
            resumo_curto.append("- Respostas HTTP 5xx relacionadas às falhas identificadas.")
        if "EXCEPTION" in unique_causes and len(unique_causes) == 1:
            resumo_curto.append("- Exceções genéricas identificadas nos logs.")

    resumo_curto.append("O relatório completo contém trechos e evidências detalhadas.")
    resumo_curto.append(f"Relatórios disponíveis em: {txt_path} e {md_path}")

    # Exibir
    for linha in resumo_curto:
        print(color(linha, C.CYAN))

    print(color("===== FIM =====", C.BOLD))

if __name__ == "__main__":
    main()
