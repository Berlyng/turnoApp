import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  // Controladores de los campos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // 🆕 ESTADO PARA LA SELECCIÓN DE ROL
  final List<String> _roles = ['cliente', 'barbero'];
  String _selectedRole = 'cliente'; // Valor por defecto

  /// FUNCIÓN DE REGISTRO
  void _register() async {
    // Validamos formulario antes de todo
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 🆕 LLAMADA AL SERVICIO CON EL ROL SELECCIONADO
      final user = await _authService.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole, // <-- Se pasa el rol aquí
      );

      // ⚠️ IMPORTANTE: verificar que el widget sigue montado
      if (!mounted) return;

      if (user != null) {
        // ✔ Registro exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario registrado con éxito 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // 🔁 Navega al Login después de un pequeño delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return; // por seguridad
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        });

      } else {
        // ❌ Error de registro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar. Intenta nuevamente 😕'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Siempre apagar loading
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // 🔹 Liberar memoria (BUENA PRÁCTICA)
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// INTERFAZ
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // NOMBRE
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Ingrese su nombre.' : null,
                ),

                const SizedBox(height: 20),

                // EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) =>
                      value != null && value.contains('@')
                          ? null
                          : 'Correo no válido.',
                ),

                const SizedBox(height: 20),

                // CONTRASEÑA
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña (mín. 6 caracteres)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) =>
                      value != null && value.length >= 6
                          ? null
                          : 'Debe tener al menos 6 caracteres.',
                ),

                const SizedBox(height: 30),
                
                // 🆕 SELECTOR DE ROL
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Selecciona tu Rol',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group_add),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRole = newValue;
                          });
                        }
                      },
                      items: _roles.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value == 'cliente' 
                              ? 'Cliente (Reservar turnos)' 
                              : 'Barbero (Gestionar mi negocio)',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // BOTÓN REGISTRAR
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // TEXTO: YA TIENES CUENTA?
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}