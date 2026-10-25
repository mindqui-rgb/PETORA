import { createSupabaseClient } from "@/lib/supabase";

export default async function Home() {
  const supabase = await createSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
      <div className="z-10 w-full max-w-5xl">
        <h1 className="text-4xl font-bold">Petshop & Klinik Hewan</h1>
        <p className="mt-4 text-lg">
          {user ? `Selamat datang, ${user.email}` : "Silakan login untuk melanjutkan"}
        </p>
      </div>
    </main>
  );
}