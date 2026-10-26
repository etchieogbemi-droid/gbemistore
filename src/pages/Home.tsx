import {Link} from 'react-router-dom';
import Products from './Products';
export default function Home(){return <>
 <section className="hero"><div><div className="eyebrow">GBEMI’s STORE</div><h1>Shop confidently. We’ll keep you updated.</h1><p>Browse available products, place your request, receive payment details, and track every order stage from payment to pickup.</p><Link className="btn pink" to="/products">Shop Products</Link></div></section>
 <div className="container"><div className="section-title"><h2>Available Products</h2><Link to="/products">View all →</Link></div><Products limit={4}/></div>
 </>}