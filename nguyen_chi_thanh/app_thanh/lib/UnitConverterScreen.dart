import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();

  double? _convertedValue;
  String _fromUnit = 'Mét (m)';
  String _toUnit = 'Feet (ft)';
  String? _error;

  late AnimationController _ac;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _ac.dispose();
    super.dispose();
  }

  void _convert() {
    setState(() {
      _error = null;
      final input = double.tryParse(_controller.text);

      if (_controller.text.isEmpty) {
        _error = "Vui lòng nhập giá trị";
        _convertedValue = null;
        return;
      }

      if (input == null) {
        _error = "Vui lòng nhập số hợp lệ";
        _convertedValue = null;
        return;
      }

      if (input < 0) {
        _error = "Giá trị phải >= 0";
        _convertedValue = null;
        return;
      }

      if (_fromUnit == _toUnit) {
        _error = "Vui lòng chọn hai đơn vị khác nhau";
        _convertedValue = null;
        return;
      }

      // Logic chuyển đổi giữ nguyên 100%
      if (_fromUnit == 'Mét (m)' && _toUnit == 'Feet (ft)') {
        _convertedValue = input * 3.28084;
      } else if (_fromUnit == 'Feet (ft)' && _toUnit == 'Mét (m)') {
        _convertedValue = input / 3.28084;
      } else if (_fromUnit == 'Mét (m)' && _toUnit == 'Kilômét (km)') {
        _convertedValue = input / 1000;
      } else if (_fromUnit == 'Kilômét (km)' && _toUnit == 'Mét (m)') {
        _convertedValue = input * 1000;
      } else if (_fromUnit == 'Mét (m)' && _toUnit == 'Dặm (mile)') {
        _convertedValue = input * 0.000621371;
      } else if (_fromUnit == 'Dặm (mile)' && _toUnit == 'Mét (m)') {
        _convertedValue = input / 0.000621371;
      } else if (_fromUnit == 'Feet (ft)' && _toUnit == 'Kilômét (km)') {
        _convertedValue = input * 0.0003048;
      } else if (_fromUnit == 'Kilômét (km)' && _toUnit == 'Feet (ft)') {
        _convertedValue = input / 0.0003048;
      } else if (_fromUnit == 'Feet (ft)' && _toUnit == 'Dặm (mile)') {
        _convertedValue = input * 0.000189394;
      } else if (_fromUnit == 'Dặm (mile)' && _toUnit == 'Feet (ft)') {
        _convertedValue = input / 0.000189394;
      } else if (_fromUnit == 'Kilômét (km)' && _toUnit == 'Dặm (mile)') {
        _convertedValue = input * 0.621371;
      } else if (_fromUnit == 'Dặm (mile)' && _toUnit == 'Kilômét (km)') {
        _convertedValue = input / 0.621371;
      }

      if (_convertedValue != null) {
        _ac.forward(from: 0);
      }
    });
  }

  String _symbol(String unit) {
    if (unit.contains("m ")) return "m";
    if (unit.contains("Feet")) return "ft";
    if (unit.contains("Kilômét")) return "km";
    if (unit.contains("Dặm")) return "mile";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Chuyển Đổi Đơn Vị",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ====== Dropdown Từ / Sang =======
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(_fromUnit, (v) {
                    setState(() {
                      _fromUnit = v!;
                      _error = null;
                    });
                  }),
                ),

                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 30),
                  onPressed: () {
                    setState(() {
                      final temp = _fromUnit;
                      _fromUnit = _toUnit;
                      _toUnit = temp;
                    });
                  },
                ),

                Expanded(
                  child: _buildDropdown(_toUnit, (v) {
                    setState(() {
                      _toUnit = v!;
                      _error = null;
                    });
                  }),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ====== Nhập giá trị =======
            _buildCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Giá trị cần đổi",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: "Nhập số…",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== Nút chuyển đổi =======
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _convert,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: const Text("Chuyển Đổi", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),

            // ====== Lỗi =======
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),

            const SizedBox(height: 20),

            // ====== Kết quả =======
            if (_convertedValue != null && _error == null)
              FadeTransition(
                opacity: _fade,
                child: _buildCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kết quả",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "${_convertedValue!.toStringAsFixed(4)} ${_symbol(_toUnit)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // UI Helper Tối Giản
  // ==============================================================

  Widget _buildDropdown(String val, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          items: const [
            DropdownMenuItem(value: 'Mét (m)', child: Text("Mét (m)")),
            DropdownMenuItem(value: 'Feet (ft)', child: Text("Feet (ft)")),
            DropdownMenuItem(
              value: 'Kilômét (km)',
              child: Text("Kilômét (km)"),
            ),
            DropdownMenuItem(value: 'Dặm (mile)', child: Text("Dặm (mile)")),
          ],
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
