export const metadata = {
  title: "Diakses Dilarang - Petshop & Klinik Hewan",
};

export default function ForbiddenPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow text-center">
        <div>
          <h2 className="text-6xl font-bold text-red-600">403</h2>
          <p className="mt-4 text-xl font-semibold">Akses Dilarang</p>
          <p className="mt-2 text-sm text-gray-600">
            Anda tidak memiliki izin untuk mengakses halaman ini.
            Silakan hubungi administrator jika Anda yakin ini adalah kesalahan.
          </p>
        </div>
      </div>
    </div>
  );
}
