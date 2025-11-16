import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'models.dart';

// Formatter for power input with commas
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Parse and format with commas
    int value = int.parse(digitsOnly);
    String formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Helper function to format power for display
String formatPower(int power) {
  final formatter = NumberFormat('#,###');
  return formatter.format(power);
}

class Member {
  final String name;
  final int power;
  final BuildingType bearTrap;

  Member({
    required this.name,
    required this.power,
    required this.bearTrap,
  });
}

class MemberLocation {
  final BuildingType btType;
  final int index;

  MemberLocation(this.btType, this.index);
}

class MemberManagerDialog extends StatefulWidget {
  final Map<BuildingType, List<Member>> members;
  
  const MemberManagerDialog({super.key, required this.members});

  @override
  State<MemberManagerDialog> createState() => _MemberManagerDialogState();
}

class _MemberManagerDialogState extends State<MemberManagerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Member> _getSortedMembers(List<Member> members) {
    final sorted = List<Member>.from(members);
    sorted.sort((a, b) => _sortAscending 
        ? a.power.compareTo(b.power) 
        : b.power.compareTo(a.power));
    return sorted;
  }

  List<MapEntry<Member, MemberLocation>> _getAllMembers() {
    final allMembers = <MapEntry<Member, MemberLocation>>[];
    
    widget.members[BuildingType.btMember1]?.asMap().forEach((index, member) {
      allMembers.add(MapEntry(member, MemberLocation(BuildingType.btMember1, index)));
    });
    widget.members[BuildingType.btMember2]?.asMap().forEach((index, member) {
      allMembers.add(MapEntry(member, MemberLocation(BuildingType.btMember2, index)));
    });
    widget.members[BuildingType.btMember3]?.asMap().forEach((index, member) {
      allMembers.add(MapEntry(member, MemberLocation(BuildingType.btMember3, index)));
    });
    
    allMembers.sort((a, b) => _sortAscending 
        ? a.key.power.compareTo(b.key.power) 
        : b.key.power.compareTo(a.key.power));
    
    return allMembers;
  }

  void _addMember(BuildingType btType) {
    _showMemberDialog(btType, null, -1);
  }

  void _editMember(BuildingType btType, Member member, int index) {
    _showMemberDialog(btType, member, index);
  }

  void _showMemberDialog(BuildingType btType, Member? existingMember, int index) {
    final nameController = TextEditingController(text: existingMember?.name ?? '');
    final powerController = TextEditingController(
      text: existingMember != null ? formatPower(existingMember.power) : '',
    );
    BuildingType selectedTrap = existingMember?.bearTrap ?? BuildingType.bearTrap1;
    final isEdit = existingMember != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Member' : 'Add Member',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: powerController,
                      decoration: const InputDecoration(
                        labelText: 'Power',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BuildingType>(
                      value: selectedTrap,
                      decoration: const InputDecoration(
                        labelText: 'Bear Trap',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: BuildingType.bearTrap1,
                          child: Text('Bear Trap 1'),
                        ),
                        DropdownMenuItem(
                          value: BuildingType.bearTrap2,
                          child: Text('Bear Trap 2'),
                        ),
                        DropdownMenuItem(
                          value: BuildingType.bearTrap3,
                          child: Text('Bear Trap 3'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedTrap = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isEmpty ||
                            powerController.text.isEmpty) {
                          return;
                        }
                        // Remove commas before parsing
                        final powerText = powerController.text.replaceAll(',', '');
                        final member = Member(
                          name: nameController.text,
                          power: int.tryParse(powerText) ?? 0,
                          bearTrap: selectedTrap,
                        );
                        setState(() {
                          if (isEdit) {
                            widget.members[btType]?[index] = member;
                          } else {
                            widget.members[btType]?.add(member);
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text(isEdit ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteMember(BuildingType btType, int index) {
    setState(() {
      widget.members[btType]?.removeAt(index);
    });
  }

  String _getTrapName(BuildingType type) {
    switch (type) {
      case BuildingType.bearTrap1:
        return 'Trap 1';
      case BuildingType.bearTrap2:
        return 'Trap 2';
      case BuildingType.bearTrap3:
        return 'Trap 3';
      default:
        return '';
    }
  }

  String _getBTName(BuildingType type) {
    switch (type) {
      case BuildingType.btMember1:
        return 'BT 1';
      case BuildingType.btMember2:
        return 'BT 2';
      case BuildingType.btMember3:
        return 'BT 3';
      default:
        return '';
    }
  }

  Widget _buildAllMembersList() {
    final allMembers = _getAllMembers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addMember(BuildingType.btMember1),
                      icon: const Icon(Icons.add),
                      label: const Text('Add to BT 1'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addMember(BuildingType.btMember2),
                      icon: const Icon(Icons.add),
                      label: const Text('Add to BT 2'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addMember(BuildingType.btMember3),
                      icon: const Icon(Icons.add),
                      label: const Text('Add to BT 3'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Total Members: ${allMembers.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: allMembers.isEmpty
              ? const Center(
                  child: Text(
                    'No members added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: allMembers.length,
                  itemBuilder: (context, index) {
                    final entry = allMembers[index];
                    final member = entry.key;
                    final location = entry.value;
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _editMember(location.btType, member, location.index),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipRect(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    radius: 14,
                                    child: Text(
                                      '#${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Power: ${formatPower(member.power)}',
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_getTrapName(member.bearTrap)} | ${_getBTName(location.btType)}',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 14),
                                    color: Colors.blue,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                    onPressed: () => _editMember(location.btType, member, location.index),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 14),
                                    color: Colors.red,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () => _deleteMember(location.btType, location.index),
                                  ),
                                ],
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMemberList(BuildingType btType) {
    final members = _getSortedMembers(widget.members[btType] ?? []);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _addMember(btType),
            icon: const Icon(Icons.add),
            label: const Text('Add Member'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: members.isEmpty
              ? const Center(
                  child: Text(
                    'No members added yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.5,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final originalIndex = (widget.members[btType] ?? []).indexOf(member);
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _editMember(btType, member, originalIndex),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: ClipRect(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange,
                                    radius: 16,
                                    child: Text(
                                      '#${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      member.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Power: ${formatPower(member.power)}',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _getTrapName(member.bearTrap),
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    color: Colors.blue,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () => _editMember(btType, member, originalIndex),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16),
                                    color: Colors.red,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    onPressed: () => _deleteMember(btType, originalIndex),
                                  ),
                                ],
                              ),
                            ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Member Manager',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Tabs and Sort button
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue.shade700,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue.shade700,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'BT 1'),
                      Tab(text: 'BT 2'),
                      Tab(text: 'BT 3'),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.blue.shade700,
                  ),
                  tooltip: _sortAscending ? 'Sort: Power Ascending' : 'Sort: Power Descending',
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                ),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllMembersList(),
                  _buildMemberList(BuildingType.btMember1),
                  _buildMemberList(BuildingType.btMember2),
                  _buildMemberList(BuildingType.btMember3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
