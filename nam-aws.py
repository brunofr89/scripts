import boto3

def get_account_name():
  """Retorna o nome da conta AWS."""

  session = boto3.Session()
  account_id = session.client("sts").get_caller_identity()["Account"]
  return account_id

if __name__ == "__main__":
  account_name = get_account_name()
  print(f"O nome da conta AWS é: {account_name}")