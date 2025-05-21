import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swift_order/buyer/event/buyer_event_list_page.dart';
import 'package:swift_order/service/event_service.dart';

class BuyerEventCreatePage extends StatefulWidget {
  const BuyerEventCreatePage({super.key});

  @override
  State<BuyerEventCreatePage> createState() => _BuyerEventCreatePageState();
}

class _BuyerEventCreatePageState extends State<BuyerEventCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  DateTime? _eventDate;
  String _searchQuery = '';
  final EventService _eventService = EventService();
  final List<String> _selectedVendorIds = [];

  @override
  void dispose() {
    _eventNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Event"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name
              TextFormField(
                controller: _eventNameController,
                decoration: InputDecoration(
                  labelText: 'Event Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter event name' : null,
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator:
                    (value) => value!.isEmpty ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16),

              // Event Date Picker
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const Text("Event Date:", style: TextStyle(fontSize: 16)),
                  Text(
                    _eventDate == null
                        ? 'Not selected'
                        : '${_eventDate!.toLocal()}'.split(' ')[0],
                    style: TextStyle(
                      fontSize: 16,
                      color: _eventDate == null ? Colors.grey : Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text("Select Date"),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _eventDate = date;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Vendor Selection Section
              const Text(
                "Invite Vendors",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),

              // Vendor Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search vendors...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Vendor List
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchVendors(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading vendors: ${snapshot.error}'),
                    );
                  }

                  final vendors = snapshot.data ?? [];

                  if (vendors.isEmpty) {
                    return const Center(child: Text('No vendors found'));
                  }

                  // Apply search filter
                  final _ =
                      _searchQuery.isEmpty
                          ? vendors
                          : vendors.where((vendor) {
                            final name =
                                vendor['name'].toString().toLowerCase();
                            final vendorName =
                                vendor['vendorName'].toString().toLowerCase();
                            final query = _searchQuery.toLowerCase();
                            return name.contains(query) ||
                                vendorName.contains(query);
                          }).toList();

                  return Column(
                    children: [
                      // Selected Vendors Chips
                      if (_selectedVendorIds.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _selectedVendorIds.map((vendorId) {
                                  final vendor = vendors.firstWhere(
                                    (v) => v['id'] == vendorId,
                                    orElse: () => {'name': 'Unknown Vendor'},
                                  );
                                  return Chip(
                                    label: Text(vendor['name']),
                                    avatar: CircleAvatar(
                                      child: Text(vendor['name'][0]),
                                      radius: 12,
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedVendorIds.remove(vendorId);
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Vendor List
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: vendors.length,
                          itemBuilder: (context, index) {
                            final vendor = vendors[index];
                            final vendorId = vendor['id'];
                            final vendorName = vendor['name'];
                            final isSelected = _selectedVendorIds.contains(
                              vendorId,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(vendorName[0]),
                                ),
                                title: Text(vendorName),
                                subtitle: Text(vendor['description'] ?? ''),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedVendorIds.add(vendorId);
                                      } else {
                                        _selectedVendorIds.remove(vendorId);
                                      }
                                    });
                                  },
                                ),
                                onTap: () {
                                  setState(() {
                                    if (_selectedVendorIds.contains(vendorId)) {
                                      _selectedVendorIds.remove(vendorId);
                                    } else {
                                      _selectedVendorIds.add(vendorId);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Create Event Button
              Center(
                child: ElevatedButton(
                  onPressed: _submitEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    "Create Event",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchVendors() async {
    try {
      // Query the 'users' collection where 'vendorId' exists
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('vendors')
              .where(
                'vendorId',
                isNotEqualTo: null,
              ) // This finds all vendor accounts
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name':
              data['vendorName'] ??
              'Unnamed Vendor', // Using vendorName from your data
          'vendorName': data['vendorName'] ?? '',
          'description': data['vendorDescription'] ?? '',
        };
      }).toList();
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching vendors: $e');
      throw Exception('Failed to fetch vendors: $e');
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event date')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You need to be logged in')));
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _eventService.createEvent(
        buyerId: user.uid,
        eventName: _eventNameController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _eventDate!,
        invitedVendorIds: _selectedVendorIds,
      );

      // Remove loading indicator
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );

      // Navigate to event list page (replace with your destination)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  BuyerEventListPage(), // Replace with your target page
        ),
      );
    } catch (e) {
      // Remove loading indicator if there's an error
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create event: ${e.toString()}')),
      );
    }
  }
}
