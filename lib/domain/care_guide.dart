// lib/domain/care_guide.dart
// Panduan perhatian & aksi romantis untuk pasangan per fase siklus. Murni Dart.

import 'cycle_engine.dart';

class CareItem {
  final String id;
  final String title;
  final String description;
  final String emoji;

  const CareItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });
}

/// Daftar aksi perhatian penuh kasih sayang untuk pasangan sesuai fase siklusnya.
List<CareItem> careGuideForPhase(CyclePhase? phase) => switch (phase) {
      CyclePhase.menstrual => const [
          CareItem(
            id: 'm_tea',
            title: 'Sajikan Minuman Hangat',
            description: 'Buatkan teh chamomile, air jahe madu, atau cokelat hangat untuk menenangkan perutnya.',
            emoji: '☕',
          ),
          CareItem(
            id: 'm_compress',
            title: 'Siapkan Kompres Hangat',
            description: 'Bantu hangatkan bantalan pemanas atau botol air hangat untuk meredakan kram di perutnya.',
            emoji: '🌸',
          ),
          CareItem(
            id: 'm_rest',
            title: 'Beri Waktu Istirahat Tenang',
            description: 'Jangan ajak aktivitas fisik berat. Siapkan bantal yang empuk dan suasana santai.',
            emoji: '🛋️',
          ),
          CareItem(
            id: 'm_cravings',
            title: 'Tanyakan Makanan yang Diinginkan',
            description: 'Tanya dengan lembut: "Sayang lagi pengen makan atau ngemil apa? Biar aku yang beliin ya."',
            emoji: '🍫',
          ),
        ],
      CyclePhase.luteal => const [
          CareItem(
            id: 'l_listen',
            title: 'Dengarkan Tanpa Menghakimi',
            description: 'Fase PMS bisa membuat emosinya sensitif. Beri telinga untuk mendengar keluh kesahnya.',
            emoji: '🫂',
          ),
          CareItem(
            id: 'l_praise',
            title: 'Beri Pujian & Afirmasi Tulus',
            description: 'Katakan betapa cantiknya dia hari ini dan betapa kamu sangat bersyukur memilikinya.',
            emoji: '✨',
          ),
          CareItem(
            id: 'l_sweet',
            title: 'Bawakan Camilan Favorit',
            description: 'Camilan manis atau es krim favoritnya bisa sangat membantu mendongkrak suasana hati.',
            emoji: '🧁',
          ),
          CareItem(
            id: 'l_peace',
            title: 'Hindari Perdebatan Kecil',
            description: 'Kendalikan ego dan bersikaplah lebih sabar. Pelukan hangat jauh lebih ia butuhkan saat ini.',
            emoji: '🤍',
          ),
        ],
      CyclePhase.follicular => const [
          CareItem(
            id: 'f_date',
            title: 'Ajak Kencan Seru Berdua',
            description: 'Energi dan semangatnya sedang naik. Waktu sempurna untuk coba kafe estetik atau restoran baru.',
            emoji: '🌷',
          ),
          CareItem(
            id: 'f_walk',
            title: 'Jalan Sore / Aktivitas Terbuka',
            description: 'Ajak jalan santai di taman atau cari udara segar berdua sambil mengobrol santai.',
            emoji: '🍃',
          ),
          CareItem(
            id: 'f_future',
            title: 'Bicarakan Ide & Rencana Bersama',
            description: 'Fokus pikirannya sedang jernih dan kreatif. Seru sekali mendiskusikan rencana liburan bersama.',
            emoji: '🗺️',
          ),
        ],
      CyclePhase.fertile || CyclePhase.ovulation => const [
          CareItem(
            id: 'o_special',
            title: 'Malam Kencan Romantis',
            description: 'Luangkan waktu berkualitas berdua tanpa gangguan gawai. Bikin suasana jadi intim dan manis.',
            emoji: '🕯️',
          ),
          CareItem(
            id: 'o_photo',
            title: 'Abadikan Momen Manisnya',
            description: 'Auranya sedang bersinar terang di puncak masa subur. Ambil foto-foto cantiknya hari ini.',
            emoji: '📸',
          ),
          CareItem(
            id: 'o_flower',
            title: 'Beri Kejutan Manis',
            description: 'Sekuntum bunga atau catatan kecil tak terduga akan membuatnya tersenyum seharian.',
            emoji: '💐',
          ),
        ],
      CyclePhase.delayed => const [
          CareItem(
            id: 'd_calm',
            title: 'Ciptakan Rasa Aman & Tenang',
            description: 'Haidnya terlambat dari jadwal perkiraan. Jangan membuatnya cemas atau terbebani.',
            emoji: '🕊️',
          ),
          CareItem(
            id: 'd_massage',
            title: 'Pijatan Lembut di Pundak',
            description: 'Bantu rilekskan tubuhnya dari stres dengan pijatan ringan dan kata-kata yang menenangkan.',
            emoji: '💆‍♀️',
          ),
          CareItem(
            id: 'd_support',
            title: 'Katakan Kamu Selalu Ada',
            description: 'Yakinkan bahwa apa pun yang ia rasakan, kamu selalu berada di sampingnya.',
            emoji: '🤝',
          ),
        ],
      null => const [
          CareItem(
            id: 'n_care',
            title: 'Tanyakan Kabar Hari Ini',
            description: 'Kirim pesan manis di tengah kesibukan: "Semangat ya manis, kangen kamu!"',
            emoji: '🎀',
          ),
        ],
    };
