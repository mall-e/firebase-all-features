import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'dart:io';



class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLogin = true; // true: giriş, false: kayıt
  bool _isLoading = false;
  bool _isPhoneAuth = false; // telefon doğrulama ekranını göster/gizle

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();

  String? _verificationId;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

  // Email ve şifre ile giriş yapma fonksiyonu
  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Giriş yapma
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim()
        );
        _navigateToHomeScreen();
      } else {
        // Kayıt olma
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim()
        );

        // Kullanıcı profilini güncelleme (isim ekleme)
        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        // E-posta doğrulama gönderme
        await userCredential.user?.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! E-posta doğrulama bağlantısı gönderildi.'))
        );

        setState(() {
          _isLogin = true; // Kayıt olduktan sonra giriş ekranına dön
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Bu e-posta adresine sahip bir kullanıcı bulunamadı.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Yanlış şifre girdiniz.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Bu e-posta adresi zaten kullanımda.';
        } else if (e.code == 'weak-password') {
          _errorMessage = 'Şifre çok zayıf.';
        } else {
          _errorMessage = 'Bir hata oluştu: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Google ile giriş yapma fonksiyonu
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Kullanıcı Google giriş işlemini iptal etti
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _navigateToHomeScreen();
    } catch (e) {
      setState(() {
        _errorMessage = 'Google ile giriş başarısız: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Apple ile giriş yapma fonksiyonu
  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      await _auth.signInWithCredential(oauthCredential);
      _navigateToHomeScreen();
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple ile giriş başarısız: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Facebook ile giriş yapma fonksiyonu
  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.token,
        );

        await _auth.signInWithCredential(credential);
        _navigateToHomeScreen();
      } else {
        setState(() {
          _errorMessage = 'Facebook ile giriş başarısız: ${result.message}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Facebook ile giriş başarısız: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Telefon numarası ile giriş yapma - Doğrulama kodu gönderme
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android'de otomatik algılama
          await _auth.signInWithCredential(credential);
          _navigateToHomeScreen();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Telefon doğrulama hatası: ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _isLoading = false;
            _verificationId = verificationId;
            // SMS kodu gönderildi, kod giriş ekranını göster
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doğrulama kodu gönderildi!'))
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Bir hata oluştu: $e';
      });
    }
  }

  // Telefon doğrulama kodunu onaylama
  Future<void> _signInWithPhoneNumber() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      _navigateToHomeScreen();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Kod doğrulama hatası: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Şifremi unuttum fonksiyonu
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen şifre sıfırlama için e-posta adresinizi girin.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.'))
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Şifre sıfırlama hatası: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Anonim giriş yapma
  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInAnonymously();
      _navigateToHomeScreen();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Anonim giriş hatası: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Giriş başarılı olduktan sonra ana sayfaya yönlendirme
  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo ve başlık
                const Icon(
                  Icons.security,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  _isPhoneAuth
                    ? 'Telefon ile Giriş'
                    : (_isLogin ? 'Hoş Geldiniz' : 'Hesap Oluştur'),
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Hata mesajı
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Telefon doğrulama ekranı
                if (_isPhoneAuth) _buildPhoneAuthForm()

                // Email/şifre ekranı
                else _buildEmailPasswordForm(),

                const SizedBox(height: 24),

                // Diğer giriş yöntemleri
                if (!_isPhoneAuth) _buildSocialLoginButtons(),

                // Telefon doğrulama geçişi
                if (!_isPhoneAuth) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isPhoneAuth = true;
                        _errorMessage = null;
                      });
                    },
                    child: const Text('Telefon Numarası ile Giriş Yap'),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isPhoneAuth = false;
                        _errorMessage = null;
                      });
                    },
                    child: const Text('E-posta ile Giriş Yap'),
                  ),
                ],

                // Anonim giriş
                TextButton(
                  onPressed: _signInAnonymously,
                  child: const Text('Misafir Olarak Devam Et'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // E-posta ve şifre form ekranı
  Widget _buildEmailPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kayıt olurken isim alanı
        if (!_isLogin) ...[
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
        ],

        // E-posta alanı
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Şifre alanı
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Şifre',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _signInWithEmailAndPassword(),
        ),

        // Şifremi unuttum butonu
        if (_isLogin) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              child: const Text('Şifremi Unuttum'),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Giriş/Kayıt butonu
        ElevatedButton(
          onPressed: _isLoading ? null : _signInWithEmailAndPassword,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
        ),

        const SizedBox(height: 16),

        // Giriş/Kayıt geçiş linki
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_isLogin
                ? 'Hesabınız yok mu?'
                : 'Zaten bir hesabınız var mı?'),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = null;
                });
              },
              child: Text(_isLogin ? 'Kayıt Ol' : 'Giriş Yap'),
            ),
          ],
        ),
      ],
    );
  }

  // Telefon doğrulama formu
  Widget _buildPhoneAuthForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Telefon numarası alanı
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefon Numarası',
            prefixIcon: Icon(Icons.phone),
            hintText: '+90 5XX XXX XX XX',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),

        // Doğrulama kodu göndermeden önce
        if (_verificationId == null) ...[
          ElevatedButton(
            onPressed: _isLoading ? null : _verifyPhoneNumber,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Doğrulama Kodu Gönder'),
          ),
        ]

        // Doğrulama kodu gönderildikten sonra
        else ...[
          TextField(
            controller: _smsCodeController,
            decoration: const InputDecoration(
              labelText: 'Doğrulama Kodu',
              prefixIcon: Icon(Icons.sms),
              hintText: '6 haneli kodu girin',
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isLoading ? null : _signInWithPhoneNumber,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kodu Doğrula ve Giriş Yap'),
          ),

          const SizedBox(height: 8),

          TextButton(
            onPressed: _isLoading ? null : _verifyPhoneNumber,
            child: const Text('Kodu Tekrar Gönder'),
          ),
        ],
      ],
    );
  }

  // Sosyal medya giriş butonları
  Widget _buildSocialLoginButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('veya şununla devam et:'),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        // Google ile giriş butonu
        OutlinedButton.icon(
          icon: Image.asset(
            'assets/google_logo.png',
            height: 24,
          ),
          label: const Text('Google ile Giriş Yap'),
          onPressed: _isLoading ? null : _signInWithGoogle,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 12),

        // Facebook ile giriş butonu
        OutlinedButton.icon(
          icon: const Icon(Icons.facebook, color: Colors.blue),
          label: const Text('Facebook ile Giriş Yap'),
          onPressed: _isLoading ? null : _signInWithFacebook,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),

        // Apple ile giriş butonu (sadece iOS platformunda göster)
        if (Platform.isIOS || Platform.isMacOS) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.apple, color: Colors.black),
            label: const Text('Apple ile Giriş Yap'),
            onPressed: _isLoading ? null : _signInWithApple,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide.none,
            ),
          ),
        ],
      ],
    );
  }
}

// Giriş başarılı olduktan sonra gösterilecek ana sayfa
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Giriş yapmış kullanıcı bilgisi
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthenticationScreen()),
              );
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kullanıcı profil fotoğrafı
              if (user?.photoURL != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user!.photoURL!),
                ),

              const SizedBox(height: 16),

              // Kullanıcı bilgileri
              Text(
                'Hoş Geldiniz${user?.displayName != null ? ', ${user?.displayName}' : ''}!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // E-posta bilgisi
              if (user?.email != null)
                Text(
                  'E-posta: ${user?.email}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

              // Telefon bilgisi
              if (user?.phoneNumber != null)
                Text(
                  'Telefon: ${user?.phoneNumber}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

              // E-posta doğrulama
              if (user?.emailVerified == false && user?.email != null) ...[
                const SizedBox(height: 16),
                Text(
                  'E-posta adresiniz doğrulanmamış.',
                  style: TextStyle(color: Colors.orange),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await user?.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Doğrulama e-postası gönderildi!'))
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e'))
                      );
                    }
                  },
                  child: const Text('Doğrulama E-postası Gönder'),
                ),
              ],

              // Anonim oturum bilgisi
              if (user?.isAnonymous == true) ...[
                const SizedBox(height: 16),
                const Text(
                  'Şu anda misafir olarak giriş yaptınız. Hesabınızı kalıcı hale getirmek için e-posta ve şifre ekleyebilirsiniz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.amber, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Anonim hesabı gerçek hesaba yükseltme sayfasına yönlendir
                    // Bu örnek için bu kısım atlandı
                  },
                  child: const Text('Hesabımı Yükselt'),
                ),
              ],

              // Kullanıcı son giriş zamanı
              if (user?.metadata.lastSignInTime != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Son giriş: ${user?.metadata.lastSignInTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
