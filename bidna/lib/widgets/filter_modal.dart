import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  final RangeValues currentRange;
  final String currentStatus;
  final Function(RangeValues, String) onApply; // callback ส่งค่ากลับ

  const FilterModal({
    super.key,
    required this.currentRange,
    required this.currentStatus,
    required this.onApply,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late RangeValues _tempRange;
  late String _tempStatus;

  @override
  void initState() {
    super.initState();
    _tempRange = widget.currentRange;
    _tempStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    //หาความสูงจอ เพื่อเอามากำหนดขอบเขต
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      //จำกัดความสูงไม่ให้เกิน 80% ของหน้าจอ (กันทะลุ)
      constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filters",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempRange = const RangeValues(0, 2000);
                        _tempStatus = "All";
                      });
                    },
                    child: const Text(
                      "Reset",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const Divider(),

              // --- 1. Price Range ---
              const Text(
                "Price Range",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _tempRange,
                min: 0,
                max: 100000,
                divisions: 20,
                labels: RangeLabels(
                  "\$${_tempRange.start.round()}",
                  "\$${_tempRange.end.round()}",
                ),
                activeColor: const Color.fromRGBO(96, 103, 237, 1),
                onChanged: (RangeValues values) {
                  setState(() {
                    _tempRange = values;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("\$${_tempRange.start.round()}"),
                  Text("\$${_tempRange.end.round()}"),
                ],
              ),
              const SizedBox(height: 20),

              // --- 2. Status Chips ---
              const Text(
                "Auction Status",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ["All", "Open", "Closed"].map((status) {
                  final isSelected = _tempStatus == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: const Color.fromRGBO(96, 103, 237, 0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color.fromRGBO(96, 103, 237, 1)
                          : Colors.black,
                    ),
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _tempStatus = status;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(96, 103, 237, 1),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    widget.onApply(_tempRange, _tempStatus);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
