import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def create_app():
    app = Flask(__name__, template_folder='../templates', static_folder='../static')

    app.secret_key = os.environ.get('SECRET_KEY', 'super_secret_key_for_dam_project')

    # ✅ SAFE DEPLOYMENT DB (Render-friendly)
    app.config['SQLALCHEMY_DATABASE_URI'] = "sqlite:///grocery.db"

    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SESSION_COOKIE_HTTPONLY'] = True

    db.init_app(app)

    from .routes import main_bp
    app.register_blueprint(main_bp)

    return app