import os
import urllib
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def create_app():
    app = Flask(__name__, template_folder='../templates', static_folder='../static')
    
    # SECURITY OPTIMIZATION: Use environment variables with fallbacks
    app.secret_key = os.environ.get('SECRET_KEY', 'super_secret_key_for_dam_project')

    # Database Configuration for SQLAlchemy
    default_conn = 'DRIVER={ODBC Driver 17 for SQL Server};SERVER=.;DATABASE=GroceryStoreDAM;Trusted_Connection=yes;'
    conn_string = os.environ.get('DATABASE_URL', default_conn)
    params = urllib.parse.quote_plus(conn_string)
    
    app.config['SQLALCHEMY_DATABASE_URI'] = "mssql+pyodbc:///?odbc_connect=%s" % params
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SESSION_COOKIE_HTTPONLY'] = True # Prevent XSS Session Hijacking

    db.init_app(app)

    from .routes import main_bp
    app.register_blueprint(main_bp)

    return app

