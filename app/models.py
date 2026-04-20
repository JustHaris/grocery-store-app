from app import db
from datetime import datetime

class User(db.Model):
    __tablename__ = 'Users'
    user_id = db.Column('UserID', db.Integer, primary_key=True, autoincrement=True)
    username = db.Column('Username', db.String(50), nullable=False)
    email = db.Column('Email', db.String(100), unique=True)
    password_hash = db.Column('PasswordHash', db.String(255), nullable=False)
    role = db.Column('Role', db.String(20))
    created_at = db.Column('CreatedAt', db.DateTime, default=datetime.utcnow)

class Category(db.Model):
    __tablename__ = 'Categories'
    category_id = db.Column('CategoryID', db.Integer, primary_key=True, autoincrement=True)
    name = db.Column('Name', db.String(100), nullable=False)
    description = db.Column('Description', db.Text)
    image_url = db.Column('ImageUrl', db.String(255))

    products = db.relationship('Product', backref='category', lazy=True)

class Product(db.Model):
    __tablename__ = 'Products'
    product_id = db.Column('ProductID', db.Integer, primary_key=True, autoincrement=True)
    name = db.Column('Name', db.String(100), nullable=False)
    description = db.Column('Description', db.Text)
    price = db.Column('Price', db.Numeric(10, 2))
    stock = db.Column('Stock', db.Integer)
    image_url = db.Column('ImageUrl', db.String(255))
    category_id = db.Column('CategoryID', db.Integer, db.ForeignKey('Categories.CategoryID'))

class Order(db.Model):
    __tablename__ = 'Orders'
    order_id = db.Column('OrderID', db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column('UserID', db.Integer, db.ForeignKey('Users.UserID'))
    order_date = db.Column('OrderDate', db.DateTime, default=datetime.utcnow)
    status = db.Column('Status', db.String(20))
    total_amount = db.Column('TotalAmount', db.Numeric(10, 2))

    user = db.relationship('User', backref='orders', lazy=True)
    items = db.relationship('OrderItem', backref='order', lazy=True)

class OrderItem(db.Model):
    __tablename__ = 'OrderItems'
    order_item_id = db.Column('OrderItemID', db.Integer, primary_key=True, autoincrement=True)
    order_id = db.Column('OrderID', db.Integer, db.ForeignKey('Orders.OrderID'))
    product_id = db.Column('ProductID', db.Integer, db.ForeignKey('Products.ProductID'))
    quantity = db.Column('Quantity', db.Integer)
    price = db.Column('Price', db.Numeric(10, 2))

    product = db.relationship('Product')

class Wishlist(db.Model):
    __tablename__ = 'Wishlist'
    wishlist_id = db.Column('WishlistID', db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column('UserID', db.Integer, db.ForeignKey('Users.UserID'))
    product_id = db.Column('ProductID', db.Integer, db.ForeignKey('Products.ProductID'))

    product = db.relationship('Product')

class Supplier(db.Model):
    __tablename__ = 'Suppliers'
    supplier_id = db.Column('SupplierID', db.Integer, primary_key=True, autoincrement=True)
    name = db.Column('Name', db.String(100), nullable=False)
    contact_person = db.Column('ContactPerson', db.String(100))
    phone = db.Column('Phone', db.String(20))
    email = db.Column('Email', db.String(100))
    address = db.Column('Address', db.Text)
    category = db.Column('Category', db.String(50)) # e.g. Dairy, Fresh Produce

