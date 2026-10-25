import { Suspense } from "react";
import LoginForm from "@/components/auth/LoginForm";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "Login - Petshop & Klinik Hewan",
};

export default function LoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow">
        <div>
          <h2 className="text-center text-3xl font-bold">Petshop & Klinik Hewan</h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Silakan login untuk mengakses sistem
          </p>
        </div>
        <Suspense fallback={<div className="flex justify-center py-8"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div></div>}>
          <LoginForm />
        </Suspense>
      </div>
    </div>
  );
}
