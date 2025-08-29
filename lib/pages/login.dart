import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/pages/home.dart';
import 'package:travel_app/pages/signup.dart';
import 'package:travel_app/services/shared_pref.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController mailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  static const String _defaultImage =
      "https://firebasestorage.googleapis.com/v0/b/travel-community-5ce94.firebasestorage.app/o/userImages%2FuserImage.png?alt=media&token=8c82eee7-c4d5-406e-bacc-7c27ad438772";

  @override
  void dispose() {
    mailcontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  void _showSnack(Color bg, String msg) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    m?.hideCurrentSnackBar();
    m?.showSnackBar(
      SnackBar(
        backgroundColor: bg,
        content: Text(
          msg,
          style: const TextStyle(fontSize: 16.0, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> userLogin() async {
    final email = mailcontroller.text.trim();
    final password = passwordcontroller.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnack(Colors.red, "Please enter email and password");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      final uid = user.uid;

      final users = FirebaseFirestore.instance.collection('users');
      final docRef = users.doc(uid);
      final snap = await docRef.get();

      if (!snap.exists) {
        await docRef.set({
          "Name": user.displayName ?? 'Traveler',
          "Email": user.email ?? email,
          "Image": _defaultImage,
          "Id": uid,
        }, SetOptions(merge: true));
      }

      final data = (await docRef.get()).data() ?? {};
      final myname = (data["Name"] ?? "Traveler").toString();
      final myimage = (data["Image"] ?? _defaultImage).toString();
      final myemail = (data["Email"] ?? user.email ?? email).toString();

      await SharedpreferenceHelper().saveUserDisplayName(myname);
      await SharedpreferenceHelper().saveUserImage(myimage);
      await SharedpreferenceHelper().saveUserId(uid);
      await SharedpreferenceHelper().saveUserEmail(myemail);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Home(successMessage: "Login Successful"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Invalid email or password";
      if (e.code == 'user-not-found') msg = "No user found for that email";
      if (e.code == 'wrong-password') msg = "Wrong password";
      if (e.code == 'invalid-email') msg = "Invalid email";
      if (e.code == 'too-many-requests') {
        msg = "Too many attempts. Try again later.";
      }
      _showSnack(Colors.red, msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // bijela pozadina
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0),
            Center(
              child: ClipOval(
                child: Image.asset(
                  "images/login.png",
                  width: 280,
                  height: 280,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20.0),
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Login",
                style: TextStyle(
                  color: Color.fromARGB(255, 38, 118, 127),
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Email",
                style: TextStyle(
                  color: Color.fromARGB(255, 50, 155, 165),
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.only(left: 30.0),
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: mailcontroller,
                cursorColor: Colors.blueAccent,
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter your email",
                ),
                onSubmitted: (_) => userLogin(),
              ),
            ),
            const SizedBox(height: 20.0),
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text(
                "Password",
                style: TextStyle(
                  color: Color.fromARGB(255, 50, 155, 165),
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.only(left: 30.0),
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                obscureText: _obscure,
                controller: passwordcontroller,
                cursorColor: Colors.blueAccent,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter your password",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                onSubmitted: (_) => userLogin(),
              ),
            ),

            const SizedBox(height: 30.0),
            // Sign in button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : userLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 38, 118, 127),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            "Sign in",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ),

            const SizedBox(height: 40.0),
            const Center(
              child: Text(
                "Don't have an account?",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUp()),
                );
              },
              child: const Center(
                child: Text(
                  "Signup",
                  style: TextStyle(
                    color: Color.fromARGB(255, 50, 155, 165),
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
