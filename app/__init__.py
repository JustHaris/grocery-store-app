import urllib
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def create_app():
    app = Flask(__name__, template_folder='../templates', static_folder='../static')
    app.secret_key = 'super_secret_key_for_dam_project'

    # Database Configuration for SQLAlchemy
    params = urllib.parse.quote_plus('DRIVER={ODBC Driver 17 for SQL Server};SERVER=.;DATABASE=GroceryStoreDAM;Trusted_Connection=yes;')
    app.config['SQLALCHEMY_DATABASE_URI'] = "mssql+pyodbc:///?odbc_connect=%s" % params
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)

    from .routes import main_bp
    app.register_blueprint(main_bp)

    return app

