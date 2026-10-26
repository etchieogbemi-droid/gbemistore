import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export type Role = 'customer' | 'admin';
export type OrderStatus = 'fresh' | 'paid' | 'processing' | 'on_way' | 'pickup' | 'completed';

export const STATUS_LABELS: Record<OrderStatus,string> = {
  fresh:'Fresh Order — Send Account Details',
  paid:'Received Payment',
  processing:'Processing',
  on_way:'On Its Way — Expected in 3 Days',
  pickup:'Pickup Station Details',
  completed:'Completed'
};

export type Profile = {
  id:string; full_name:string; phone:string; email:string; location:string; role:Role; created_at:string;
};
export type Product = {
  id:string; code:string; name:string; description:string; price:number; stock_quantity:number; created_at:string; updated_at:string;
  product_images?: {id:string; image_url:string; sort_order:number}[];
};
