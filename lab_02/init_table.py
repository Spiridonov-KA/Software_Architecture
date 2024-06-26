import os
import sys

from faker import Faker
from sqlalchemy import create_engine, text


def main(count=100):
    login = os.getenv('DB_LOGIN')
    password = os.getenv('DB_PASSWORD')
    host = os.getenv('DB_HOST')
    db = os.getenv('DB_DATABASE')

    engine = create_engine(f"postgresql://{login}:{password}@{host}/{db}", echo=True)
    faker = Faker()

    # default_password = 'password'
    # word 'password' after hashing
    default_password = '4b007901b765489abead49d926f721d065a429c12e463f6c4cd79401085b03dbc7e8b88f1447f8c33c8e087a29a3bfcd895eb6fbf381dcd92caf12199a34037fc7834095ddfae0bca22a12c35ddbb672edad29634d66f8f9accbf9b267f969a34e7ea30247507342e4e710e9ccb782b46faab487580fa1c809d37f5cb2bd7397' 

    with engine.connect() as con:
        con.execute(text('DROP TABLE IF EXISTS users'))
        con.execute(text('''\
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(256) NOT NULL,
    last_name VARCHAR(256) NOT NULL,
    login VARCHAR(256)  NULL,
    password VARCHAR(256)  NULL,
    email VARCHAR(256) NULL,
    phone VARCHAR(1024) NULL,
    address VARCHAR(1024) NULL
)'''))
        con.execute(text('CREATE INDEX nameIndex ON users (first_name, last_name)'))
        con.execute(text('CREATE INDEX loginIndex ON users (login)'))
        for _ in range(count):
            first_name, last_name = faker.name().split(' ', 1)
            con.execute(text(
                "INSERT INTO users (first_name, last_name, login, password, email, phone, address) "
                f"VALUES ('{first_name}', '{last_name}', '{faker.user_name()}', '{default_password}', '{faker.free_email()}', '{faker.phone_number()}', '{faker.address()}')"
            ))
        con.commit()


if __name__ == '__main__':
    num = int(sys.argv[1])
    main(num)
