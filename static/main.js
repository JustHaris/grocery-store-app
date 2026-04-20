// ============================================================
// GroceryStore Main JS - Fully Consolidated
// ============================================================

document.addEventListener('DOMContentLoaded', () => {

    // 1. Animate on Scroll (Simple AOS)
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-up');
                entry.target.style.opacity = '1';
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    document.querySelectorAll('[data-aos="fade-up"]').forEach(el => observer.observe(el));

    // 2. Horizontal Scroll for Categories
    const slider = document.querySelector('.category-slider');
    if (slider) {
        let isDown = false, startX, scrollLeft;
        slider.addEventListener('mousedown', (e) => {
            isDown = true;
            startX = e.pageX - slider.offsetLeft;
            scrollLeft = slider.scrollLeft;
        });
        slider.addEventListener('mouseleave', () => { isDown = false; });
        slider.addEventListener('mouseup', () => { isDown = false; });
        slider.addEventListener('mousemove', (e) => {
            if (!isDown) return;
            e.preventDefault();
            slider.scrollLeft = scrollLeft - (e.pageX - slider.offsetLeft - startX) * 2;
        });
    }

    // 3. Hero Banner Auto-Slide
    const slides = document.querySelectorAll('.hero-slide');
    if (slides.length > 0) {
        let currentSlide = 0;
        setInterval(() => {
            slides[currentSlide].classList.remove('active');
            currentSlide = (currentSlide + 1) % slides.length;
            slides[currentSlide].classList.add('active');
        }, 5000);
    }

    // 4. Back to Top Button
    const backToTop = document.getElementById('back-to-top');
    if (backToTop) {
        window.addEventListener('scroll', () => {
            backToTop.classList.toggle('d-none', window.scrollY <= 500);
        });
        backToTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
    }

    // 5. Theme Initialization
    const savedTheme = localStorage.getItem('theme') || 'dark';
    document.documentElement.setAttribute('data-theme', savedTheme);
    const themeBtn = document.getElementById('theme-toggle');
    if (themeBtn) themeBtn.innerHTML = savedTheme === 'dark' ? '<i class="bi bi-moon-stars"></i>' : '<i class="bi bi-sun"></i>';

    // 6. Sidebar State Persistence
    const sidebar = document.getElementById('main-sidebar');
    const toggleBtn = document.getElementById('sidebar-toggle');
    const isCollapsedSaved = localStorage.getItem('sidebar-collapsed') === 'true';
    if (isCollapsedSaved && window.innerWidth > 1024 && sidebar) {
        sidebar.classList.add('collapsed');
        _updateToggleIcon(toggleBtn, false);
    }

    // 7. Create Mobile Overlay (once)
    if (window.innerWidth <= 1024 && !document.querySelector('.sidebar-overlay')) {
        const overlay = document.createElement('div');
        overlay.className = 'sidebar-overlay';
        overlay.onclick = toggleSidebar;
        document.body.appendChild(overlay);
    }

});

// ============================================================
// Global Functions (called from HTML onclick attributes)
// ============================================================

function toggleSidebar() {
    const sidebar = document.getElementById('main-sidebar');
    if (!sidebar) return;
    let overlay = document.querySelector('.sidebar-overlay');

    // Create overlay if missing (edge case on first call before DOMContentLoaded completes)
    if (!overlay) {
        overlay = document.createElement('div');
        overlay.className = 'sidebar-overlay';
        overlay.onclick = toggleSidebar;
        document.body.appendChild(overlay);
    }

    const toggleBtn = document.getElementById('sidebar-toggle');

    if (window.innerWidth <= 1024) {
        const isOpen = sidebar.classList.toggle('active');
        overlay.classList.toggle('active', isOpen);
        _updateToggleIcon(toggleBtn, isOpen);
    } else {
        const isCollapsed = sidebar.classList.toggle('collapsed');
        localStorage.setItem('sidebar-collapsed', isCollapsed);
        _updateToggleIcon(toggleBtn, !isCollapsed);
    }
}

function _updateToggleIcon(btn, isOpen) {
    if (!btn) return;
    const icon = btn.querySelector('i');
    if (!icon) return;
    if (window.innerWidth <= 1024) {
        icon.className = isOpen ? 'bi bi-x-lg fs-4' : 'bi bi-list fs-3';
    } else {
        icon.className = isOpen ? 'bi bi-layout-sidebar fs-4' : 'bi bi-layout-sidebar-inset fs-4';
    }
}

function toggleTheme() {
    const html = document.documentElement;
    const next = html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    html.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    const btn = document.getElementById('theme-toggle');
    if (btn) btn.innerHTML = next === 'dark' ? '<i class="bi bi-moon-stars"></i>' : '<i class="bi bi-sun"></i>';
}

function filterInventory() {
    const input = document.getElementById('adminSearch');
    if (!input) return;
    const filter = input.value.toUpperCase();
    const table = document.querySelector('.dash-table');
    if (!table) return;
    const rows = table.getElementsByTagName('tr');
    for (let i = 1; i < rows.length; i++) {
        const tdName = rows[i].getElementsByTagName('td')[0];
        const tdCat = rows[i].getElementsByTagName('td')[1];
        if (tdName && tdCat) {
            const txt = (tdName.textContent + ' ' + tdCat.textContent).toUpperCase();
            rows[i].style.display = txt.includes(filter) ? '' : 'none';
        }
    }
}

async function addToCart(productId, quantity = 1) {
    try {
        const response = await fetch('/api/add_to_cart/' + productId, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ quantity: quantity })
        });
        
        const data = await response.json();
        
        if (response.status === 401) {
            window.location.href = data.redirect;
            return;
        }

        const toast = new bootstrap.Toast(document.getElementById('liveToast'));
        const toastMsg = document.getElementById('toastMessage');
        const toastEl = document.getElementById('liveToast');
        
        if (data.success) {
            toastEl.classList.remove('text-bg-danger');
            toastEl.classList.add('text-bg-success');
            toastMsg.textContent = data.message;
            // Optionally update cart badge here if you have one
        } else {
            toastEl.classList.remove('text-bg-success');
            toastEl.classList.add('text-bg-danger');
            toastMsg.textContent = data.message;
        }
        toast.show();
        
    } catch (error) {
        console.error('Error adding to cart:', error);
    }
}

