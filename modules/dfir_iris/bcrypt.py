import bcrypt
print(bcrypt.hashpw('socarium'.encode('utf-8'), bcrypt.gensalt()))