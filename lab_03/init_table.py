import os
import random

import click
from faker import Faker
from faker.providers import phone_number
from sqlalchemy import create_engine, text
import bson
from pymongo import MongoClient

@click.group()
def cli():
    pass

@cli.command('postgres')
@click.option('--count', '-n', default=0)
@click.option('--create-table', is_flag=True)
def postgres(count=0, create_table=False):
    login = os.getenv('DB_LOGIN')
    password = os.getenv('DB_PASSWORD')
    host = os.getenv('DB_HOST')
    db = os.getenv('DB_DATABASE')

    engine = create_engine(f"postgresql://{login}:{password}@{host}/{db}", echo=True)
    faker = Faker()
    faker.add_provider(phone_number)

    # all generated users have password 'password'
    default_password = '4b007901b765489abead49d926f721d065a429c12e463f6c4cd79401085b03dbc7e8b88f1447f8c33c8e087a29a3bfcd895eb6fbf381dcd92caf12199a34037fc7834095ddfae0bca22a12c35ddbb672edad29634d66f8f9accbf9b267f969a34e7ea30247507342e4e710e9ccb782b46faab487580fa1c809d37f5cb2bd7397'

    with engine.connect() as con:
        if create_table:
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

        for _ in range(count):
            first_name, last_name = faker.name().split(' ', 1)
            con.execute(text(
                "INSERT INTO users (first_name, last_name, login, password, email, phone, address) "
                f"VALUES ('{first_name}', '{last_name}', '{faker.user_name()}', '{default_password}', '{faker.free_email()}', '{faker.phone_number()}', '{faker.address()}')"
            ))
        con.commit()

@cli.command('mongodb')
@click.option('--users-count', required=True, type=int)
@click.option('--services-count', default=0, type=int)
@click.option('--services-in-orders', default=0, type=int)
def mongodb(users_count, services_count=0, services_in_orders=0):
    try:
        client = MongoClient(os.getenv('DB_HOST'), int(os.getenv('DB_PORT')))
        db = client.archdb
        services_collection = db.services
        services_collection.drop()
        orders_collection = db.orders
        orders_collection.drop()
    except:
        raise Exception('Can`t establish connection to database')
    
    faker = Faker()
    for i in range(services_count):
        service = {
            "_id": str(i),
            "name": faker.text(max_nb_chars=10),
            "price": random.randrange(1, 1000)
        }
        services_collection.insert_one(service)

    for i in range(users_count):
        order = []
        for j in range(random.randrange(0, services_in_orders+1)):
            order.append(str(random.randrange(services_count)))
        order = {
            "_id": str(i),
            "services": order
        }
        orders_collection.insert_one(order)

if __name__ == '__main__':
    cli()
