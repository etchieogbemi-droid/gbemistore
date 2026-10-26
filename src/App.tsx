import {useEffect,useState} from 'react';
import {Routes,Route,Link,useNavigate} from 'react-router-dom';
import {supabase,Profile} from './lib/supabase';
import Home from './pages/Home';
import Products from './pages/Products';
import Auth from './pages/Auth';
import Account from './pages/Account';
import Admin from './pages/Admin';

export default function App(){
 const [profile,setProfile]=useState<Profile|null>(null);
 useEffect(()=>{let mounted=true;
  supabase.auth.getSession().then(async({data})=>{if(data.session){const {data:p}=await supabase.from('profiles').select('*').eq('id',data.session.user.id).single();if(mounted)setProfile(p)}});
  const {data:{subscription}}=supabase.auth.onAuthStateChange(async(_e,s)=>{if(s){const {data:p}=await supabase.from('profiles').select('*').eq('id',s.user.id).single();if(mounted)setProfile(p)}else if(mounted)setProfile(null)});
  return()=>{mounted=false;subscription.unsubscribe()}
 },[]);
 const logout=async()=>{await supabase.auth.signOut();setProfile(null)};
 return <div className="app">
  <nav className="nav"><Link className="brand" to="/"><img src="/store-logo.png"/><span>GBEMI’s STORE</span></Link>
   <div className="navlinks"><Link className="hide" to="/products">Shop</Link>{profile?<><Link to="/account">My Account</Link>{profile.role==='admin'&&<Link to="/admin">Admin</Link>}<button className="btn light" onClick={logout}>Logout</button></>:<Link className="btn primary" to="/login">Login</Link>}</div>
  </nav>
  <Routes><Route path="/" element={<Home/>}/><Route path="/products" element={<Products/>}/><Route path="/login" element={<Auth/>}/><Route path="/account" element={<Account profile={profile}/>}/><Route path="/admin" element={<Admin profile={profile}/>}/></Routes>
  <footer className="footer"><b>GBEMI’s STORE</b><p className="small">Quality products. Simple ordering. Clear delivery updates.</p></footer>
 </div>
}