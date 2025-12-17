import 'package:flutter/material.dart';
import 'app_colors.dart';

class TemperatureConverterScreen extends StatefulWidget {
  const TemperatureConverterScreen({super.key});

  @override
  State<TemperatureConverterScreen> createState() =>
      _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState extends State<TemperatureConverterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  double? _convertedTemperature;
  String _fromUnit = 'Celsius';
  String _toUnit = 'Fahrenheit';
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _convertTemperature() {
    setState(() {
      _errorMessage = null;
      final input = double.tryParse(_controller.text);

      if (_controller.text.isEmpty) {
        _errorMessage = 'Vui lòng nhập nhiệt độ';
        _convertedTemperature = null;
        return;
      }

      if (input == null) {
        _errorMessage = 'Vui lòng nhập số hợp lệ';
        _convertedTemperature = null;
        return;
      }

      if (_fromUnit == _toUnit) {
        _errorMessage = 'Vui lòng chọn hai đơn vị khác nhau';
        _convertedTemperature = null;
        return;
      }

      if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') {
        _convertedTemperature = input * 9 / 5 + 32;
      } else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Celsius') {
        _convertedTemperature = (input - 32) * 5 / 9;
      } else if (_fromUnit == 'Celsius' && _toUnit == 'Kelvin') {
        _convertedTemperature = input + 273.15;
      } else if (_fromUnit == 'Kelvin' && _toUnit == 'Celsius') {
        _convertedTemperature = input - 273.15;
      } else if (_fromUnit == 'Fahrenheit' && _toUnit == 'Kelvin') {
        _convertedTemperature = (input - 32) * 5 / 9 + 273.15;
      } else if (_fromUnit == 'Kelvin' && _toUnit == 'Fahrenheit') {
        _convertedTemperature = (input - 273.15) * 9 / 5 + 32;
      }

      if (_convertedTemperature != null) {
        _animationController.forward(from: 0);
      }
    });
  }

  String _symbol(String unit) {
    switch (unit) {
      case 'Celsius':
        return '°C';
      case 'Fahrenheit':
        return '°F';
      case 'Kelvin':
        return 'K';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Chuyển Đổi Nhiệt Độ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // --------------------------
            // INPUT CARD TỐI GIẢN
            // --------------------------
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Từ",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    value: _fromUnit,
                    onChanged: (v) => setState(() => _fromUnit = v!),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Nhập nhiệt độ",
                      filled: true,
                      fillColor: Color(0xfff6f6f6),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      prefixIcon: Icon(Icons.thermostat_outlined),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------
            // BUTTON SWAP
            // --------------------------
            Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    final temp = _fromUnit;
                    _fromUnit = _toUnit;
                    _toUnit = temp;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: const Icon(Icons.swap_vert, size: 28),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------
            // OUTPUT CARD
            // --------------------------
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Sang",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _buildDropdown(
                    value: _toUnit,
                    onChanged: (v) => setState(() => _toUnit = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------
            // BUTTON CHUYỂN ĐỔI
            // --------------------------
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _convertTemperature,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: const Text(
                  "Chuyển đổi",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            if (_convertedTemperature != null && _errorMessage == null) ...[
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _animation,
                child: _buildCard(
                  child: Column(
                    children: [
                      Text(
                        _convertedTemperature!.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _symbol(_toUnit),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------
  // TÁCH COMPONENT TỐI GIẢN
  // --------------------------------------

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _buildDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down),
          items: const [
            DropdownMenuItem(value: "Celsius", child: Text("Celsius")),
            DropdownMenuItem(value: "Fahrenheit", child: Text("Fahrenheit")),
            DropdownMenuItem(value: "Kelvin", child: Text("Kelvin")),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
