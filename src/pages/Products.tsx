import {useEffect,useState} from 'react';
import {Link} from 'react-router-dom';
import {supabase,Product} from '../lib/supabase';
export default function Products({limit}:{limit?:number}){const [items,setItems]=useState<Product[]>([]);const [loading,setLoading]=useState(true);
 useEffect(()=>{supabase.from('products').select('*,product_images(*)').gt('stock_quantity',0).order('created_at',{ascending:false}).limit(limit||100).then(({data})=>{setItems(data||[]);setLoading(false)})},[limit]);
 if(loading)return <div className="container">Loading products…</div>;
 return <div className="grid">{items.map(p=><div className="card" key={p.id}><img src={p.product_images?.[0]?.image_url||'/store-hero.jpg'}/><div className="cardbody"><span className="pill">{p.code}</span><h3>{p.name}</h3><p className="muted">{p.description}</p><p className="price">₦{Number(p.price).toLocaleString()}</p><p className="small">{p.stock_quantity} available</p><Link className="btn primary" to={`/account?request=${p.id}`}>Request Product</Link></div></div>)}</div>}