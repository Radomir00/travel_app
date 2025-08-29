import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/pages/home.dart';
import 'package:travel_app/pages/login.dart';
import 'package:travel_app/services/database.dart';
import 'package:travel_app/services/shared_pref.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  static const Color titleColor = Color.fromARGB(255, 38, 118, 127);
  static const Color labelColor = Color.fromARGB(255, 50, 155, 165);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController namecontroller = TextEditingController();
  final TextEditingController mailcontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();
  final TextEditingController confirmpwcontroller = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    namecontroller.dispose();
    mailcontroller.dispose();
    passwordcontroller.dispose();
    confirmpwcontroller.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter your name';
    if (t.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Enter your email';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(t)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String? v) {
    final t = (v ?? '');
    if (t.isEmpty) return 'Create a password';
    if (t.length < 8) return 'At least 8 characters';
    if (!RegExp(r'(?=.*[A-Za-z])(?=.*\d)').hasMatch(t)) {
      return 'Use letters and numbers';
    }
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != passwordcontroller.text) return 'Passwords do not match';
    return null;
  }

  Future<void> registration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = mailcontroller.text.trim();
    final password = passwordcontroller.text;
    final name = namecontroller.text.trim();

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      const defaultImage =
          "https://firebasestorage.googleapis.com/v0/b/travel-community-5ce94.firebasestorage.app/o/userImages%2FuserImage.png?alt=media&token=8c82eee7-c4d5-406e-bacc-7c27ad438772";

      final userInfoMap = {
        "Name": name,
        "Email": email,
        "Image": defaultImage,
        "Id": uid,
      };

      await DatabaseMethods().addUserDetails(userInfoMap, uid);

      await SharedpreferenceHelper().saveUserDisplayName(name);
      await SharedpreferenceHelper().saveUserEmail(email);
      await SharedpreferenceHelper().saveUserId(uid);
      await SharedpreferenceHelper().saveUserImage(defaultImage);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Registered Successfully",
            style: TextStyle(fontSize: 20.0, color: Colors.white),
          ),
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Registration failed. Try again.";
      Color bg = Colors.red;
      if (e.code == 'weak-password') {
        msg = "Password Provided is too Weak";
        bg = Colors.orangeAccent;
      } else if (e.code == 'email-already-in-use') {
        msg = "Account Already exists";
        bg = Colors.orangeAccent;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: bg,
          content: Text(
            msg,
            style: const TextStyle(fontSize: 18.0, color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
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
                  "Signup",
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12.0),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        "Name",
                        style: TextStyle(
                          color: labelColor,
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
                      child: TextFormField(
                        controller: namecontroller,
                        cursorColor: Colors.blueAccent,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your name",
                        ),
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        "Email",
                        style: TextStyle(
                          color: labelColor,
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
                      child: TextFormField(
                        controller: mailcontroller,
                        keyboardType: TextInputType.emailAddress,
                        cursorColor: Colors.blueAccent,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your email",
                        ),
                        validator: _validateEmail,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        "Password",
                        style: TextStyle(
                          color: labelColor,
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
                      child: TextFormField(
                        controller: passwordcontroller,
                        obscureText: _obscure,
                        cursorColor: Colors.blueAccent,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Create a password",
                          suffixIcon: IconButton(
                            onPressed:
                                () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0),
                      child: Text(
                        "Confirm Password",
                        style: TextStyle(
                          color: labelColor,
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
                      child: TextFormField(
                        controller: confirmpwcontroller,
                        obscureText: _obscureConfirm,
                        cursorColor: Colors.blueAccent,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Repeat your password",
                          suffixIcon: IconButton(
                            onPressed:
                                () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        validator: _validateConfirm,
                        onFieldSubmitted: (_) => registration(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              GestureDetector(
                onTap: _isLoading ? null : registration,
                child: Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: titleColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
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
                              "Sign up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              const Center(
                child: Text(
                  "Already have an account?",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    _isLoading
                        ? null
                        : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()),
                          );
                        },
                child: const Center(
                  child: Text(
                    "Signin",
                    style: TextStyle(
                      color: labelColor,
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
      ),
    );
  }
}
