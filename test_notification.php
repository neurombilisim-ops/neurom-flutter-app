<?php
// Test bildirimi oluşturmak için geçici script
require_once 'E:/21.09.2025/Eticaret paytr düzeltilmiş olan/htdocs/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Notifications\OrderNotification;

// Laravel uygulamasını başlat
$app = require_once 'E:/21.09.2025/Eticaret paytr düzeltilmiş olan/htdocs/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

// Kullanıcı ID 205'i bul (loglardan gördüğümüz)
$user = User::find(205);

if ($user) {
    echo "Kullanıcı bulundu: " . $user->name . "\n";
    
    // Test bildirimi oluştur
    $order_notification = [
        'order_id' => 999,
        'order_code' => 'TEST-001',
        'user_id' => 205,
        'seller_id' => 1,
        'status' => 'placed',
        'notification_type_id' => 1
    ];
    
    // Bildirimi gönder
    $user->notify(new OrderNotification($order_notification));
    
    echo "Test bildirimi gönderildi!\n";
    
    // Bildirimleri kontrol et
    $notifications = $user->notifications()->get();
    echo "Toplam bildirim sayısı: " . $notifications->count() . "\n";
    
    $unreadNotifications = $user->unreadNotifications()->get();
    echo "Okunmamış bildirim sayısı: " . $unreadNotifications->count() . "\n";
    
} else {
    echo "Kullanıcı bulunamadı!\n";
}
?>

