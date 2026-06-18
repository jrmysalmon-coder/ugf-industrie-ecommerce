// Types Supabase - regenerer avec: npm run db:types

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

  export type ProductStatus = 'active' | 'inactive'
  export type OrderStatus = 'pending' | 'paid' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
  export type ProfileStatus = 'pending' | 'active' | 'suspended'
  export type QuoteStatus = 'pending' | 'sent' | 'accepted' | 'refused'

  export interface Database {
    public: {
          Tables: {
                  products: {
                            Row: { id: string; sku: string; name: string; slug: string; description: string | null; price: number; stock: number; category_id: string | null; brand_id: string | null; images: string[]; specs: Json; active: boolean; created_at: string; updated_at: string }
                            Insert: Omit<Database['public']['Tables']['products']['Row'], 'id' | 'created_at' | 'updated_at'>
                                      Update: Partial<Database['public']['Tables']['products']['Insert']>
                  }
                  profiles: {
                            Row: { id: string; user_id: string; company_name: string; siret: string | null; address: Json; phone: string | null; status: ProfileStatus; created_at: string }
                            Insert: Omit<Database['public']['Tables']['profiles']['Row'], 'id' | 'created_at'>
                                      Update: Partial<Database['public']['Tables']['profiles']['Insert']>
                  }
                  orders: {
                            Row: { id: string; user_id: string; status: OrderStatus; total: number; stripe_payment_id: string | null; shipping_address: Json; created_at: string; updated_at: string }
                            Insert: Omit<Database['public']['Tables']['orders']['Row'], 'id' | 'created_at' | 'updated_at'>
                                      Update: Partial<Database['public']['Tables']['orders']['Insert']>
                  }
          }
          Views: Record<string, never>
                Functions: Record<string, never>
                      Enums: Record<string, never>
    }
}
