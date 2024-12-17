import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'screens/menu_screen.dart'; // Import MenuScreen
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino Runner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MenuScreenWrapper(), // Ganti home dengan MenuScreenWrapper
    );
  }
}

class MenuScreenWrapper extends StatelessWidget {
  const MenuScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MenuScreen(
      onStartGame: () {
        // Tambahkan logika untuk menghitung mundur 3 detik
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        });
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0;
  bool isPlaying = false;
  double dinoY = 0;
  double dinoX = 50;
  double groundY = 0;
  final double gravity = 1.5;
  Timer? gameTimer;
  List<double> obstacleX = [
    800,
    1000,
    1200,
    1400,
    1600
  ]; // Mulai dengan 5 rintangan
  List<double> obstacleY = [0, -30, -20, -40, -10]; // Variasi ketinggian awal
  double obstacleSpeed = 5; // Kecepatan awal
  double baseSpeed = 5; // Kecepatan dasar
  final TextEditingController _answerController = TextEditingController();
  Timer? _questionTimer; // Timer untuk soal
  int _timeLeft = 10; // Waktu untuk menjawab (dalam detik)
  late AudioPlayer audioPlayer; // Gunakan 'late' untuk inisialisasi nanti
  Timer? countdownTimer; // Pastikan countdownTimer dideklarasikan
  int countdown = 3; // Tambahkan deklarasi variabel countdown
  bool showCountdown = true; // Tambahkan variable ini
  bool isPaused = false; // Tambahkan variable untuk status pause
  late AudioPlayer backgroundMusicPlayer;
  late AudioPlayer soundEffectPlayer;

  Map<String, dynamic> generateMathProblem() {
    Random random = Random();
    int num1 = random.nextInt(10) + 1; // angka 1-10
    int num2 = random.nextInt(10) + 1;

    // Pilih operasi random (tambah/kurang/kali)
    int operation = random.nextInt(3);
    String operationSymbol;
    int answer;

    switch (operation) {
      case 0:
        operationSymbol = '+';
        answer = num1 + num2;
        break;
      case 1:
        operationSymbol = '-';
        answer = num1 - num2;
        break;
      case 2:
        operationSymbol = 'x';
        answer = num1 * num2;
        break;
      default:
        operationSymbol = '+';
        answer = num1 + num2;
    }

    return {'question': '$num1 $operationSymbol $num2 = ?', 'answer': answer};
  }

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    backgroundMusicPlayer = AudioPlayer();
    soundEffectPlayer = AudioPlayer();
    startCountdown();
  }

  void startCountdown() {
    setState(() {
      showCountdown = true;
      countdown = 3;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        countdownTimer?.cancel();
        setState(() {
          showCountdown = false;
        });
        startGame(
            continueGame:
                false); // Mulai permainan setelah hitungan mundur selesai
      }
    });
  }

  Future<void> playBackgroundMusic() async {
    try {
      // Pastikan sound effect lain berhenti
      await soundEffectPlayer.stop();

      await backgroundMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await backgroundMusicPlayer
          .setSource(AssetSource('audio/soundtrack.mp3'));
      await backgroundMusicPlayer.setVolume(0.5);
      await backgroundMusicPlayer.resume();
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  void startGame({bool continueGame = false}) async {
    try {
      setState(() {
        isPlaying = true;
        if (!continueGame) {
          score = 0;
        }
        dinoY = 0;
        obstacleX = [800, 1000, 1200, 1400, 1600];
        obstacleY =
            List.generate(5, (index) => -70 + Random().nextDouble() * 70);
      });

      await playBackgroundMusic(); // Tunggu audio siap

      gameTimer?.cancel();
      gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        updateGame();
      });
    } catch (e) {
      print('Error in startGame: $e');
    }
  }

  void playGameOverSound() async {
    try {
      // Hentikan musik latar dan sound effect lain
      await backgroundMusicPlayer.stop();
      await soundEffectPlayer.stop();

      await soundEffectPlayer.setSource(AssetSource('audio/game_over.wav'));
      await soundEffectPlayer.resume();
    } catch (e) {
      print('Error playing game over sound: $e');
    }
  }

  void playCountdownSound() async {
    try {
      // Hentikan semua suara yang sedang bermain
      await backgroundMusicPlayer.stop();
      await soundEffectPlayer.stop();

      await soundEffectPlayer.setSource(AssetSource('audio/countdown.mp3'));
      await soundEffectPlayer.resume();
    } catch (e) {
      print('Error playing countdown sound: $e');
    }
  }

  void updateGame() {
    if (isPaused) return; // Jika game di-pause, jangan update

    setState(() {
      score++;

      // Update kecepatan berdasarkan score
      obstacleSpeed =
          baseSpeed + (score ~/ 500); // Setiap 500 poin, kecepatan bertambah 1

      // Update posisi rintangan
      for (int i = 0; i < obstacleX.length; i++) {
        obstacleX[i] -= obstacleSpeed;
      }

      // Tambah rintangan baru dengan jarak lebih dekat
      if (obstacleX.last < 600) {
        obstacleX.add(obstacleX.last +
            200 +
            Random().nextDouble() * 100); // Jarak random 200-300
        obstacleY.add(-70 + Random().nextDouble() * 70);
      }

      // Hapus rintangan yang sudah lewat
      while (obstacleX.isNotEmpty && obstacleX[0] < -60) {
        obstacleX.removeAt(0);
        obstacleY.removeAt(0);
      }

      // Pastikan selalu ada minimal 5 rintangan
      while (obstacleX.length < 5) {
        double lastX = obstacleX.isEmpty ? 800 : obstacleX.last + 200;
        obstacleX.add(lastX);
        obstacleY.add(-70 + Random().nextDouble() * 70);
      }

      // Cek tabrakan
      for (int i = 0; i < obstacleX.length; i++) {
        if (obstacleX[i] <= dinoX + 60 &&
            obstacleX[i] + 60 >= dinoX &&
            dinoY >= obstacleY[i] - 60 &&
            dinoY <= obstacleY[i] + 60) {
          gameOver();
        }
      }

      // Apply gravity
      dinoY += gravity;
      if (dinoY > 0) {
        dinoY = 0;
      }
    });
  }

  void jump() {
    if (dinoY >= 0) {
      setState(() {
        dinoY = -20;
      });
    }
  }

  void moveUp() {
    setState(() {
      if (dinoY > -200) {
        dinoY -= 50;
      }
    });
  }

  void moveDown() {
    setState(() {
      if (dinoY < 0) {
        dinoY += 50;
      }
    });
  }

  void gameOver() {
    int _hintCount = 0; // Counter hint yang digunakan
    const int _maxHints = 2; // Batas maksimal hint
    String _hintMessage = ''; // Hint yang diberikan AI

    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
    });

    playGameOverSound();

    _timeLeft = 10;
    Map<String, dynamic> problem = generateMathProblem();

    StateSetter? _dialogSetState;

    // Tunggu sound game over selesai baru mainkan countdown
    Future.delayed(const Duration(seconds: 1), () {
      playCountdownSound();
    });

    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _dialogSetState?.call(() {
          _timeLeft--;
        });
      } else {
        _questionTimer?.cancel();
        Navigator.pop(context);
        _answerController.clear();
        startGame(continueGame: true);
      }
    });

    int _aiUsageCount = 0; // Variabel untuk menghitung penggunaan AI
    const int _maxAIUsage = 2; // Batas maksimal penggunaan AI

    Future<String> _fetchAIAnswer(String question) async {
      const String apiKey =
          "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";
      const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Authorization": "Bearer $apiKey",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "model": "llama3-8b-8192",
            "messages": [
              {
                "role": "system",
                "content":
                    "Jawab soal matematika yang diberikan pengguna dengan singkat dan langsung memberikan jawaban yang benar."
              },
              {"role": "user", "content": "Soal: $question"},
            ],
            "temperature": 0.3,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'].trim();
        } else {
          return "Gagal mendapatkan jawaban. Coba lagi nanti.";
        }
      } catch (e) {
        return "Terjadi kesalahan: $e";
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          _dialogSetState = setState;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Kena Rintangan!',
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Score: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Waktu: $_timeLeft detik',
                  style: TextStyle(
                    color: _timeLeft <= 3 ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Jawab soal ini untuk melanjutkan:'),
                Text(
                  problem['question'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: _answerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan jawaban',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 10),
                if (_hintMessage.isNotEmpty) // Tampilkan hint jika ada
                  Text(
                    'Jawaban AI: $_hintMessage',
                    style: const TextStyle(
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  int? userAnswer = int.tryParse(_answerController.text);
                  if (userAnswer == problem['answer']) {
                    _questionTimer?.cancel();
                    Navigator.pop(context);
                    _answerController.clear();
                    startGame(continueGame: true);
                  } else {
                    _questionTimer?.cancel();
                    Navigator.pop(context);
                    _answerController.clear();
                    showGameOverDialog();
                  }
                },
                child: const Text('Jawab'),
              ),
              TextButton(
                onPressed: () {
                  _questionTimer?.cancel();
                  Navigator.pop(context);
                  _answerController.clear();
                  showGameOverDialog();
                },
                child: const Text('Menyerah'),
              ),
              if (_aiUsageCount < _maxAIUsage) // Cek batas penggunaan AI
                TextButton(
                  onPressed: () async {
                    if (_aiUsageCount < _maxAIUsage) {
                      _aiUsageCount++;
                      _hintMessage = await _fetchAIAnswer(problem['question']);
                      setState(() {});
                    }
                  },
                  child:
                      Text('Jawaban AI (${_maxAIUsage - _aiUsageCount} sisa)'),
                ),
              if (_aiUsageCount >= _maxAIUsage)
                const Text(
                  'AI hanya bisa digunakan 2 kali per game.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          );
        },
      ),
    ).then((_) {
      _questionTimer?.cancel();
      _hintMessage = ''; // Reset hint saat dialog ditutup
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Score Akhir: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0; // Reset score
                startGame(); // Mulai game baru
              });
            },
            child: const Text('Main Lagi'),
          ),
        ],
      ),
    );
  }

  void pauseGame() {
    if (!isPlaying || showCountdown) return;
    setState(() {
      isPaused = true;
      gameTimer?.cancel();
      backgroundMusicPlayer.pause();
    });
  }

  void resumeGame() {
    if (!isPlaying || showCountdown) return;
    setState(() {
      isPaused = false;
      gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        updateGame();
      });
      backgroundMusicPlayer.resume();
    });
  }

  Future<void> stopAllSounds() async {
    try {
      await backgroundMusicPlayer.stop();
      await soundEffectPlayer.stop();
    } catch (e) {
      print('Error stopping sounds: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 50),
                // Score display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Score: $score',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Tambahkan tombol pause di sini
                      if (isPlaying && !showCountdown)
                        IconButton(
                          onPressed: isPaused ? resumeGame : pauseGame,
                          icon: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            color: const Color(0xFF2196F3),
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Game area
                Expanded(
                  child: Stack(
                    children: [
                      // Ground dengan tampilan lebih menarik
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B4513),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      // Dino character
                      Positioned(
                        left: dinoX,
                        bottom: 2 - dinoY,
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: Image.asset(
                            'assets/dino2.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // Tambahkan rintangan
                      for (int i = 0; i < obstacleX.length; i++)
                        Positioned(
                          left: obstacleX[i],
                          bottom: 2 - obstacleY[i],
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: Image.asset(
                              'assets/rintangan1.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Control buttons dengan tampilan lebih menarik
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: !isPlaying ? startGame : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          isPlaying ? 'Playing...' : 'Start Game',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (isPlaying) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            onPressed: moveUp,
                            icon: const Icon(Icons.arrow_upward,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            onPressed: moveDown,
                            icon: const Icon(Icons.arrow_downward,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            onPressed: isPaused ? resumeGame : pauseGame,
                            icon: Icon(
                              isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Overlay pause
            if (isPaused)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'PAUSED',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: resumeGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Resume',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Navigasi kembali ke MenuScreen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    MenuScreen(onStartGame: () {})),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Menu',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (showCountdown)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    countdown.toString(),
                    style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    stopAllSounds();
    countdownTimer?.cancel();
    _questionTimer?.cancel();
    _answerController.dispose();
    gameTimer?.cancel();
    audioPlayer.dispose();
    backgroundMusicPlayer.dispose();
    soundEffectPlayer.dispose();
    super.dispose();
  }
}
