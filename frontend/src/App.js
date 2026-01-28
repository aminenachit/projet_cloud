import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const API_BASE_URL = process.env.REACT_APP_API_URL || '';

function App() {
  const [activeTab, setActiveTab] = useState('products');
  const [products, setProducts] = useState([]);
  const [orders, setOrders] = useState([]);
  const [cart, setCart] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const [newProduct, setNewProduct] = useState({
    name: '',
    description: '',
    price: '',
    stock: ''
  });

  const [orderForm, setOrderForm] = useState({
    customer_name: '',
    customer_email: ''
  });

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.get(`${API_BASE_URL}/api/products/products/`);
      setProducts(response.data);
    } catch (err) {
      setError('Erreur lors du chargement des produits');
      console.error(err);
    }
    setLoading(false);
  };

  const fetchOrders = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await axios.get(`${API_BASE_URL}/api/orders/orders/`);
      setOrders(response.data);
    } catch (err) {
      setError('Erreur lors du chargement des commandes');
      console.error(err);
    }
    setLoading(false);
  };

  const addProduct = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await axios.post(`${API_BASE_URL}/api/products/products/`, {
        name: newProduct.name,
        description: newProduct.description,
        price: parseFloat(newProduct.price),
        stock: parseInt(newProduct.stock)
      });
      setNewProduct({ name: '', description: '', price: '', stock: '' });
      fetchProducts();
      alert('Produit ajouté avec succès!');
    } catch (err) {
      setError('Erreur lors de l\'ajout du produit');
      console.error(err);
    }
    setLoading(false);
  };

  const addToCart = (product) => {
    const existingItem = cart.find(item => item.product_id === product.id);
    if (existingItem) {
      setCart(cart.map(item =>
        item.product_id === product.id
          ? { ...item, quantity: item.quantity + 1 }
          : item
      ));
    } else {
      setCart([...cart, { product_id: product.id, quantity: 1, product }]);
    }
    alert(`${product.name} ajouté au panier!`);
  };

  const removeFromCart = (productId) => {
    setCart(cart.filter(item => item.product_id !== productId));
  };

  const placeOrder = async (e) => {
    e.preventDefault();
    if (cart.length === 0) {
      alert('Votre panier est vide!');
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const orderData = {
        customer_name: orderForm.customer_name,
        customer_email: orderForm.customer_email,
        items: cart.map(item => ({
          product_id: item.product_id,
          quantity: item.quantity
        }))
      };

      await axios.post(`${API_BASE_URL}/api/orders/orders/`, orderData);
      setCart([]);
      setOrderForm({ customer_name: '', customer_email: '' });
      alert('Commande passée avec succès!');
      setActiveTab('orders');
      fetchOrders();
    } catch (err) {
      setError(err.response?.data?.detail || 'Erreur lors de la commande');
      console.error(err);
    }
    setLoading(false);
  };

  const getTotalCart = () => {
    return cart.reduce((total, item) => {
      return total + (item.product.price * item.quantity);
    }, 0).toFixed(2);
  };

  useEffect(() => {
    if (activeTab === 'orders') {
      fetchOrders();
    }
  }, [activeTab]);

  return (
    <div className="App">
      <header className="header">
        <h1>🛒 E-Commerce Mini App</h1>
        <p>Projet Kubernetes - Microservices</p>
      </header>

      <nav className="tabs">
        <button
          className={activeTab === 'products' ? 'active' : ''}
          onClick={() => setActiveTab('products')}
        >
          📦 Produits
        </button>
        <button
          className={activeTab === 'add-product' ? 'active' : ''}
          onClick={() => setActiveTab('add-product')}
        >
          ➕ Ajouter Produit
        </button>
        <button
          className={activeTab === 'cart' ? 'active' : ''}
          onClick={() => setActiveTab('cart')}
        >
          🛒 Panier ({cart.length})
        </button>
        <button
          className={activeTab === 'orders' ? 'active' : ''}
          onClick={() => setActiveTab('orders')}
        >
          📋 Commandes
        </button>
      </nav>

      {error && <div className="error">{error}</div>}
      {loading && <div className="loading">Chargement...</div>}

      <main className="content">
        {activeTab === 'products' && (
          <div className="products-grid">
            {products.map(product => (
              <div key={product.id} className="product-card">
                <h3>{product.name}</h3>
                <p className="description">{product.description}</p>
                <p className="price">{product.price} €</p>
                <p className="stock">Stock: {product.stock}</p>
                <button
                  onClick={() => addToCart(product)}
                  disabled={product.stock === 0}
                >
                  {product.stock > 0 ? 'Ajouter au panier' : 'Rupture de stock'}
                </button>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'add-product' && (
          <div className="form-container">
            <h2>Ajouter un nouveau produit</h2>
            <form onSubmit={addProduct}>
              <input
                type="text"
                placeholder="Nom du produit"
                value={newProduct.name}
                onChange={(e) => setNewProduct({...newProduct, name: e.target.value})}
                required
              />
              <textarea
                placeholder="Description"
                value={newProduct.description}
                onChange={(e) => setNewProduct({...newProduct, description: e.target.value})}
              />
              <input
                type="number"
                step="0.01"
                placeholder="Prix (€)"
                value={newProduct.price}
                onChange={(e) => setNewProduct({...newProduct, price: e.target.value})}
                required
              />
              <input
                type="number"
                placeholder="Stock"
                value={newProduct.stock}
                onChange={(e) => setNewProduct({...newProduct, stock: e.target.value})}
                required
              />
              <button type="submit">Ajouter le produit</button>
            </form>
          </div>
        )}

        {activeTab === 'cart' && (
          <div className="cart-container">
            <h2>Votre Panier</h2>
            {cart.length === 0 ? (
              <p className="empty-cart">Votre panier est vide</p>
            ) : (
              <>
                <div className="cart-items">
                  {cart.map(item => (
                    <div key={item.product_id} className="cart-item">
                      <h3>{item.product.name}</h3>
                      <p>Prix unitaire: {item.product.price} €</p>
                      <p>Quantité: {item.quantity}</p>
                      <p className="subtotal">Sous-total: {(item.product.price * item.quantity).toFixed(2)} €</p>
                      <button onClick={() => removeFromCart(item.product_id)}>Retirer</button>
                    </div>
                  ))}
                </div>
                <div className="cart-total">
                  <h3>Total: {getTotalCart()} €</h3>
                </div>
                <form onSubmit={placeOrder} className="order-form">
                  <h3>Informations de commande</h3>
                  <input
                    type="text"
                    placeholder="Nom complet"
                    value={orderForm.customer_name}
                    onChange={(e) => setOrderForm({...orderForm, customer_name: e.target.value})}
                    required
                  />
                  <input
                    type="email"
                    placeholder="Email"
                    value={orderForm.customer_email}
                    onChange={(e) => setOrderForm({...orderForm, customer_email: e.target.value})}
                    required
                  />
                  <button type="submit">Passer la commande</button>
                </form>
              </>
            )}
          </div>
        )}

        {activeTab === 'orders' && (
          <div className="orders-container">
            <h2>Historique des commandes</h2>
            {orders.length === 0 ? (
              <p className="empty-orders">Aucune commande pour le moment</p>
            ) : (
              <div className="orders-list">
                {orders.map(order => (
                  <div key={order.id} className="order-card">
                    <h3>Commande #{order.id}</h3>
                    <p>Client: {order.customer_name}</p>
                    <p>Email: {order.customer_email}</p>
                    <p>Total: {order.total_amount} €</p>
                    <p className={`status status-${order.status}`}>
                      Statut: {order.status}
                    </p>
                    <div className="order-items">
                      <h4>Articles:</h4>
                      {order.items.map(item => (
                        <p key={item.id}>
                          {item.product_name} x{item.quantity} - {item.price} €
                        </p>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
