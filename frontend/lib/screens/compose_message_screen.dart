import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../providers/auth_provider.dart';
import '../providers/lease_provider.dart';
import '../providers/message_provider.dart';
import '../providers/property_provider.dart';
import '../providers/unit_provider.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  String _messageType = 'direct'; // 'direct' or 'group'
  int? _selectedPropertyId;
  int? _selectedReceiverId;
  int? _landlordId;
  bool _isTenant = false;
  bool _isLoadingInit = true;
  
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _initData();
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final provider = Provider.of<MessageProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).userName ?? 'User';
    
    // Determine room name
    String room = '';
    if (_messageType == 'group' && _selectedPropertyId != null) {
      room = 'group_$_selectedPropertyId';
    } else if (_selectedReceiverId != null) {
      room = 'user_$_selectedReceiverId'; // This logic might need refinement for 1-on-1 rooms
    }

    if (room.isNotEmpty) {
      if (_contentController.text.isNotEmpty) {
        provider.sendTyping(room, user);
      } else {
        provider.sendStopTyping(room, user);
      }
    }
  }

  Future<void> _pickImage() async {
    bool permissionGranted = false;
    
    if (kIsWeb) {
      permissionGranted = true;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) {
        permissionGranted = true;
      } else {
        final requestStatus = await Permission.photos.request();
        if (requestStatus.isGranted) {
          permissionGranted = true;
        } else {
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isGranted) {
            permissionGranted = true;
          } else {
             final storageRequest = await Permission.storage.request();
             permissionGranted = storageRequest.isGranted;
          }
        }
      }
    } else {
      final status = await Permission.photos.request();
      permissionGranted = status.isGranted;
    }

    if (permissionGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = pickedFile;
          _webImageBytes = bytes;
          _base64Image = base64Encode(bytes);
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied to access gallery')),
        );
      }
    }
  }

  Future<void> _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _isTenant = auth.userRole == 'tenant';

    if (_isTenant) {
      _messageType = 'group'; // Tenants cannot send Direct Messages initially
    }

    if (_isTenant) {
      // For tenant, fetch leases to find their property
      final leaseProvider = Provider.of<LeaseProvider>(context, listen: false);
      if (auth.userId != null) {
        await leaseProvider.fetchLeases(auth.userId!);
        final activeLease = leaseProvider.leases.firstWhere(
          (l) => l.status == 'active' || l.status == 'pending',
          orElse: () => leaseProvider.leases.isNotEmpty ? leaseProvider.leases.first : null as dynamic,
        );

        if (activeLease != null) {
          // We need to fetch the unit to get the property ID
          // Since lease has unit details included (based on backend controller), we might access it directly
          // But the Lease model in frontend might need checking.
          // Assuming we can get propertyId from the unit in the lease.
          // If not, we might need a better way.
          // Let's assume for now we can get it or we need to fetch unit details.
          // Actually, the backend `findAllByTenant` includes `unit`.
          // Let's check the Lease model.
          
          // Workaround: If Lease model doesn't have propertyId, we might need to fetch it.
          // But wait, the backend `findAllByTenant` includes `unit`. Does `unit` include `property_id`?
          // Yes, Unit model usually has property_id.
          
          if (activeLease.unit != null) {
             final propertyId = activeLease.unit!.propertyId;
             if (propertyId != null) {
               // Fetch property details to get landlord ID
               final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
               final property = await propertyProvider.fetchPropertyById(propertyId);
               
               if (mounted) {
                 setState(() {
                   _selectedPropertyId = propertyId;
                   _landlordId = property?.landlordId;
                 });
               }
             }
          }
        }
      }
    } else {
      // Landlord
      Provider.of<PropertyProvider>(context, listen: false).fetchProperties();
    }
    
    setState(() {
      _isLoadingInit = false;
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _onPropertyChanged(int? newValue) {
    setState(() {
      _selectedPropertyId = newValue;
      _selectedReceiverId = null; // Reset receiver
    });
    if (newValue != null && _messageType == 'direct' && !_isTenant) {
      Provider.of<UnitProvider>(context, listen: false).fetchUnits(newValue);
    }
  }

  void _sendMessage() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPropertyId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property information missing')),
        );
        return;
      }
      
      // For Tenant DMing Landlord, we need to handle _selectedReceiverId
      // If tenant selects "Landlord", we need to know the Landlord's ID.
      // Currently we might not have it easily.
      // OPTION: Send a message with `receiverId: 0` or similar and let backend handle? No.
      // OPTION: Fetch property owner.
      
      if ((_messageType == 'direct' || _messageType == 'landlord') && _selectedReceiverId == null) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a recipient')),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      final message = Message(
        senderId: userId!,
        receiverId: (_messageType == 'direct' || _messageType == 'landlord') ? _selectedReceiverId : null,
        groupId: _messageType == 'group' ? _selectedPropertyId : null,
        content: _selectedImage != null ? _base64Image! : _contentController.text,
        type: _selectedImage != null ? 'image' : 'text',
      );

      // Special handling for Tenant -> Landlord
      // If _isTenant and _messageType == 'direct', we need to find the landlord ID.
      // This is a gap. I will assume for now tenants can only Group Message until I fix the Landlord ID fetch.
      // OR, I can allow them to type the ID? No.
      // I will restrict Tenants to Group Messages for this iteration if I can't get Landlord ID.
      // BUT, the user asked for "tenant can only dm the landlord or the group".
      // So I MUST implement Landlord DM.
      
      // FIX: I'll update the backend to allow sending to "LANDLORD_OF_PROPERTY" or similar?
      // Better: When tenant loads, fetch their property which SHOULD have owner_id.
      
      final provider = Provider.of<MessageProvider>(context, listen: false);
      final success = await provider.sendMessage(message);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isTenant && _selectedPropertyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compose Message'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'No Active Lease Found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You must be assigned to a unit to send messages to your property group.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Message'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message Type Dropdown
              DropdownButtonFormField<String>(
                value: _messageType,
                decoration: const InputDecoration(
                  labelText: 'Message Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: [
                  if (!_isTenant) const DropdownMenuItem(value: 'direct', child: Text('Direct Message')),
                  const DropdownMenuItem(value: 'group', child: Text('Group Message (Apartment)')),
                  if (_isTenant) const DropdownMenuItem(value: 'landlord', child: Text('Contact Landlord')), 
                ],
                onChanged: (value) {
                  setState(() {
                    _messageType = value!;
                    
                    if (value == 'landlord') {
                      // _selectedReceiverId should be set to landlord ID fetched in _initData
                      if (_landlordId != null) {
                        _selectedReceiverId = _landlordId;
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Landlord information not available.')));
                      }
                    } else {
                      _selectedReceiverId = null;
                    }
                    
                    if (_messageType == 'direct' && _selectedPropertyId != null && !_isTenant) {
                      Provider.of<UnitProvider>(context, listen: false)
                          .fetchUnits(_selectedPropertyId!);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Property Dropdown (Hidden for Tenant, they are locked to their unit's property)
              if (!_isTenant)
              Consumer<PropertyProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedPropertyId,
                    decoration: const InputDecoration(
                      labelText: 'Select Property',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.apartment),
                    ),
                    items: provider.properties.map((Property prop) {
                      return DropdownMenuItem<int>(
                        value: prop.id,
                        child: Text(prop.name),
                      );
                    }).toList(),
                    onChanged: _onPropertyChanged,
                    validator: (value) => value == null ? 'Please select a property' : null,
                  );
                },
              ),
              
              if (_isTenant && _selectedPropertyId != null)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 16.0),
                   child: Text("Messaging for Property ID: $_selectedPropertyId", style: const TextStyle(color: Colors.grey)),
                 ),

              const SizedBox(height: 16),

              // Recipient Dropdown (Only for Landlord Direct Message)
              if (_messageType == 'direct' && !_isTenant)
                Consumer<UnitProvider>(
                  builder: (context, provider, child) {
                    final occupiedUnits = provider.units
                        .where((unit) => unit.tenantId != null)
                        .toList();

                    return DropdownButtonFormField<int>(
                      value: _selectedReceiverId,
                      decoration: const InputDecoration(
                        labelText: 'Select Recipient',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: occupiedUnits.map((Unit unit) {
                        return DropdownMenuItem<int>(
                          value: unit.tenantId,
                          child: Text(
                              'Unit ${unit.unitNumber} - ${unit.tenantName ?? "Unknown"}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedReceiverId = value;
                        });
                      },
                      validator: (value) =>
                          _messageType == 'direct' && value == null
                              ? 'Please select a recipient'
                              : null,
                    );
                  },
                ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if ((value == null || value.isEmpty) && _selectedImage == null) {
                    return 'Please enter a message or select an image';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _webImageBytes != null 
                        ? Image.memory(
                            _webImageBytes!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _base64Image = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_selectedImage == null)
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Attach Image'),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ),
              const SizedBox(height: 32),
              Consumer<MessageProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Send Message',
                            style: TextStyle(fontSize: 18),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
