from flask import Blueprint, render_template, request, redirect, url_for, session, flash, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from app import db
from app.models import User, Category, Product, Order, OrderItem, Wishlist, Supplier
from sqlalchemy import func
from sqlalchemy.orm import joinedload
from functools import wraps

main_bp = Blueprint('main', __name__)

# --- Decorators ---
def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get('role') != 'Admin':
            flash('Admin access required.', 'danger')
            return redirect(url_for('main.index'))
        return f(*args, **kwargs)
    return decorated_function


# --- Authentication ---
@main_bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        identity = request.form['username']
        password = request.form['password']
        
        user = User.query.filter((User.username == identity) | (User.email == identity)).first()

        if user and check_password_hash(user.password_hash, password):
            session['user_id'] = user.user_id
            session['username'] = user.username
            session['role'] = user.role
            flash('Logged in successfully!', 'success')
            return redirect(url_for('main.index'))
        else:
            flash('Invalid username or password', 'danger')
            
    return render_template('login.html')

@main_bp.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        # SECURITY: Force role to Customer for public signups
        role = 'Customer'
        password = request.form['password']
        hashed_password = generate_password_hash(password)
        
        existing_user = User.query.filter((User.username == username) | (User.email == email)).first()
        if existing_user:
            flash('Username or Email already exists.', 'danger')
            return redirect(url_for('main.signup'))

        new_user = User(username=username, email=email, password_hash=hashed_password, role=role)

        db.session.add(new_user)
        try:
            db.session.commit()
            flash('Account created! Please log in.', 'success')
            return redirect(url_for('main.login'))
        except Exception as e:
            db.session.rollback()
            flash('Database error.', 'danger')
            
    return render_template('signup.html')


@main_bp.route('/logout')
def logout():
    session.clear()
    flash('Logged out successfully.', 'info')
    return redirect(url_for('main.index'))


# --- Customer Routes ---
@main_bp.route('/')
def index():
    search_query = request.args.get('search', '')
    category_filter = request.args.get('category', '')
    sort_by = request.args.get('sort', 'name')

    query = Product.query

    if search_query:
        query = query.filter(Product.name.ilike(f'%{search_query}%'))
        
    if category_filter:
        query = query.filter(Product.category_id == category_filter)

    if sort_by == 'price_low':
        query = query.order_by(Product.price.asc())
    elif sort_by == 'price_high':
        query = query.order_by(Product.price.desc())
    else:
        query = query.order_by(Product.name.asc())

    # OPTIMIZATION: Avoid N+1 queries by eager loading the category
    products = query.options(joinedload(Product.category)).all()
    categories = Category.query.all()
    return render_template('index.html', products=products, categories=categories)


@main_bp.route('/product/<int:product_id>')
def product_detail(product_id):
    product = Product.query.get_or_404(product_id)
    # Get related products (same category, excluding current)
    related = Product.query.filter(Product.category_id == product.category_id, Product.product_id != product_id).limit(4).all()
    return render_template('product.html', product=product, related=related)


@main_bp.route('/cart')
def view_cart():
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
    cart = session.get('cart', {})
    
    cart_items = []
    total = 0
    if cart:
        product_ids = [int(pid) for pid in cart.keys()]
        products = Product.query.filter(Product.product_id.in_(product_ids)).all()
        
        for p in products:
            quantity = cart[str(p.product_id)]
            subtotal = quantity * p.price
            total += subtotal
            cart_items.append({
                'product_id': p.product_id,
                'name': p.name,
                'price': p.price,
                'quantity': quantity,
                'subtotal': subtotal,
                'image_url': p.image_url
            })
            
    return render_template('cart.html', items=cart_items, total=total)

@main_bp.route('/add_to_cart/<int:product_id>', methods=['POST'])
def add_to_cart(product_id):
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    product = Product.query.get_or_404(product_id)
    quantity = int(request.form.get('quantity', 1))
    
    cart = session.get('cart', {})
    pid = str(product_id)
    
    current_qty = cart.get(pid, 0)
    if current_qty + quantity > product.stock:
        flash(f'Cannot add {quantity} item(s). Only {product.stock} in stock.', 'danger')
        return redirect(request.referrer or url_for('main.index'))
        
    cart[pid] = current_qty + quantity
    session['cart'] = cart
    session.modified = True
    
    flash('Item added to cart', 'success')
    return redirect(request.referrer or url_for('main.index'))

@main_bp.route('/api/add_to_cart/<int:product_id>', methods=['POST'])
def api_add_to_cart(product_id):
    """AJAX endpoint for seamless Add to Cart"""
    if 'user_id' not in session:
        return jsonify({'success': False, 'redirect': url_for('main.login')}), 401
        
    product = Product.query.get_or_404(product_id)
    
    if request.is_json:
        quantity = int(request.json.get('quantity', 1))
    else:
        quantity = int(request.form.get('quantity', 1))
    
    cart = session.get('cart', {})
    pid = str(product_id)
    
    current_qty = cart.get(pid, 0)
    if current_qty + quantity > product.stock:
        return jsonify({'success': False, 'message': f'Only {product.stock} in stock.'}), 400
        
    cart[pid] = current_qty + quantity
    session['cart'] = cart
    session.modified = True
    
    total_items = sum(cart.values())
    
    return jsonify({'success': True, 'message': 'Added to cart!', 'total_items': total_items})


@main_bp.route('/update_cart/<int:product_id>', methods=['POST'])
def update_cart(product_id):
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    cart = session.get('cart', {})
    pid = str(product_id)
    action = request.form.get('action')
    
    if pid in cart:
        if action == 'increase':
            cart[pid] += 1
        elif action == 'decrease' and cart[pid] > 1:
            cart[pid] -= 1
        session['cart'] = cart
        session.modified = True
        
    return redirect(url_for('main.view_cart'))

@main_bp.route('/remove_from_cart/<int:product_id>', methods=['POST'])
def remove_from_cart(product_id):
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    cart = session.get('cart', {})
    pid = str(product_id)
    if pid in cart:
        cart.pop(pid)
        session['cart'] = cart
        session.modified = True
        flash('Item removed from cart', 'info')
        
    return redirect(url_for('main.view_cart'))


@main_bp.route('/checkout', methods=['POST'])
def checkout():
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    cart = session.get('cart', {})
    if not cart:
        flash('Cart is empty', 'warning')
        return redirect(url_for('main.view_cart'))
        
    user_id = session['user_id']
    product_ids = [int(pid) for pid in cart.keys()]
    products = Product.query.filter(Product.product_id.in_(product_ids)).all()
    
    total_amount = 0
    
    # ACID Transaction
    try:
        new_order = Order(user_id=user_id, status='Processing', total_amount=0)
        db.session.add(new_order)
        db.session.flush() 
        
        for p in products:
            quantity = cart[str(p.product_id)]
            if p.stock < quantity:
                db.session.rollback()
                flash(f'Insufficient stock for {p.name}. Only {p.stock} available.', 'danger')
                return redirect(url_for('main.view_cart'))
                
            # Single Authority Stock Deduction
            p.stock -= quantity
            price = p.price
            total_amount += (quantity * price)
            
            order_item = OrderItem(order_id=new_order.order_id, product_id=p.product_id, quantity=quantity, price=price)
            db.session.add(order_item)
            
        new_order.total_amount = total_amount
        db.session.commit()
        
        session.pop('cart', None)
        flash('Order placed successfully!', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Checkout error: {str(e)}', 'danger')

    return redirect(url_for('main.orders'))

@main_bp.route('/orders')
def orders():
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    user_id = session['user_id']
    user_orders = Order.query.filter_by(user_id=user_id).order_by(Order.order_date.desc()).all()
    
    return render_template('orders.html', orders=user_orders)

@main_bp.route('/order/<int:order_id>/invoice')
def view_invoice(order_id):
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
    
    order = Order.query.get_or_404(order_id)
    if order.user_id != session['user_id'] and session.get('role') != 'Admin':
        flash('Unauthorized access', 'danger')
        return redirect(url_for('main.index'))
        
    return render_template('invoice.html', order=order)


@main_bp.route('/wishlist')
def wishlist():
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    user_id = session['user_id']
    wishlist_items = Wishlist.query.filter_by(user_id=user_id).all()
    
    items = []
    for w in wishlist_items:
        p = w.product
        if p:
            p.wishlist_item_id = w.wishlist_id # Store for removal
            items.append(p)

    return render_template('wishlist.html', items=items)

@main_bp.route('/add_to_wishlist/<int:product_id>', methods=['POST'])
def add_to_wishlist(product_id):
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    user_id = session['user_id']
    existing = Wishlist.query.filter_by(user_id=user_id, product_id=product_id).first()
    if not existing:
        new_wishlist = Wishlist(user_id=user_id, product_id=product_id)
        db.session.add(new_wishlist)
        try:
            db.session.commit()
            flash('Added to wishlist', 'success')
        except:
            db.session.rollback()
            flash('Failed to add to wishlist', 'danger')
    else:
        flash('Item already in wishlist', 'info')
        
    return redirect(request.referrer or url_for('main.index'))

@main_bp.route('/remove_from_wishlist/<int:wishlist_id>', methods=['POST'])
def remove_from_wishlist(wishlist_id):
    if 'user_id' not in session:
        return redirect(url_for('main.login'))
        
    item = Wishlist.query.get_or_404(wishlist_id)
    if item.user_id != session['user_id']:
        flash('Unauthorized', 'danger')
        return redirect(url_for('main.wishlist'))
        
    db.session.delete(item)
    db.session.commit()
    flash('Removed from wishlist', 'info')
    return redirect(url_for('main.wishlist'))


# --- Admin Routes ---
@main_bp.route('/admin')
@admin_required
def admin_panel():
    products = Product.query.all()
    categories = Category.query.all()
    # Simple analytics
    total_sales = db.session.query(func.sum(Order.total_amount)).filter(Order.status != 'Cancelled').scalar() or 0
    total_orders = Order.query.count()
    total_products = Product.query.count()
    low_stock_products = Product.query.filter(Product.stock <= 10).all()
    
    # Category Distribution for Chart
    cat_dist = db.session.query(Category.name, func.count(Product.product_id)).join(Product).group_by(Category.name).all()
    
    return render_template('admin.html', 
                           products=products, 
                           categories=categories,
                           revenue=total_sales, 
                           orders=total_orders, 
                           products_count=total_products, 
                           low_stock=low_stock_products,
                           cat_dist=cat_dist)

@main_bp.route('/admin/dashboard')
@admin_required
def admin_dashboard():
    total_revenue = db.session.query(func.sum(Order.total_amount)).filter(Order.status != 'Cancelled').scalar() or 0
    total_orders = Order.query.count()
    total_products = Product.query.count()
    low_stock_products = Product.query.filter(Product.stock <= 10).all()
    
    # Category Distribution for Chart
    cat_dist = db.session.query(Category.name, func.count(Product.product_id)).join(Product).group_by(Category.name).all()
    
    return render_template('dashboard.html', 
                           revenue=total_revenue, 
                           orders=total_orders, 
                           products=total_products, 
                           low_stock=low_stock_products,
                           cat_dist=cat_dist)


@main_bp.route('/admin/add_product', methods=['POST'])
@admin_required
def add_product():
    name = request.form['name']
    price = request.form['price']
    stock = request.form['stock']
    category_id = request.form['category_id']
    image_url = request.form.get('image_url')
    description = request.form.get('description')
    
    new_product = Product(name=name, price=price, stock=stock, category_id=category_id, image_url=image_url, description=description)

    db.session.add(new_product)
    try:
        db.session.commit()
        flash('Product added.', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Failed to add product: {str(e)}', 'danger')
        
    return redirect(url_for('main.admin_panel'))

@main_bp.route('/admin/edit_product/<int:product_id>', methods=['POST'])
@admin_required
def edit_product(product_id):
    product = Product.query.get_or_404(product_id)
    product.name = request.form['name']
    product.price = request.form['price']
    product.stock = request.form['stock']
    product.category_id = request.form['category_id']
    product.image_url = request.form.get('image_url')
    product.description = request.form.get('description')
    
    db.session.commit()
    flash('Product updated.', 'success')
    return redirect(url_for('main.admin_panel'))

@main_bp.route('/admin/delete_product/<int:product_id>', methods=['POST'])
@admin_required
def delete_product(product_id):
    product = Product.query.get_or_404(product_id)
    # Check if product is in any orders to maintain referential integrity
    # (Though DB has constraints, it's good to catch it here)
    ordered = OrderItem.query.filter_by(product_id=product_id).first()
    if ordered:
        flash('Cannot delete product because it exists in order history.', 'danger')
    else:
        db.session.delete(product)
        db.session.commit()
        flash('Product deleted.', 'info')
        
    return redirect(url_for('main.admin_panel'))


@main_bp.route('/suppliers')
@admin_required
def suppliers():
    supplier_list = Supplier.query.all()
    return render_template('suppliers.html', suppliers=supplier_list)

@main_bp.route('/admin/add_supplier', methods=['POST'])
@admin_required
def add_supplier():
    name = request.form['name']
    contact_person = request.form.get('contact_person')
    category = request.form.get('category')
    email = request.form.get('email')
    phone = request.form.get('phone')
    address = request.form.get('address')
    
    new_supplier = Supplier(name=name, contact_person=contact_person, category=category, email=email, phone=phone, address=address)
    
    db.session.add(new_supplier)
    try:
        db.session.commit()
        flash('Supplier registered successfully.', 'success')
    except Exception as e:
        db.session.rollback()
        flash(f'Error registering supplier: {str(e)}', 'danger')
        
    return redirect(url_for('main.suppliers'))

@main_bp.route('/admin/edit_supplier/<int:supplier_id>', methods=['POST'])
@admin_required
def edit_supplier(supplier_id):
    supplier = Supplier.query.get_or_404(supplier_id)
    supplier.name = request.form['name']
    supplier.contact_person = request.form.get('contact_person')
    supplier.category = request.form.get('category')
    supplier.email = request.form.get('email')
    supplier.phone = request.form.get('phone')
    supplier.address = request.form.get('address')
    
    db.session.commit()
    flash('Supplier updated.', 'success')
    return redirect(url_for('main.suppliers'))

@main_bp.route('/admin/delete_supplier/<int:supplier_id>', methods=['POST'])
@admin_required
def delete_supplier(supplier_id):
    supplier = Supplier.query.get_or_404(supplier_id)
    db.session.delete(supplier)
    db.session.commit()
    flash('Supplier removed.', 'info')
    return redirect(url_for('main.suppliers'))


@main_bp.app_errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404


