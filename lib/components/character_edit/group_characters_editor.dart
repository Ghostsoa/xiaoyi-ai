import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../model/character_card.dart';
import '../../service/image_service.dart';
import '../../components/custom_snack_bar.dart';

class GroupCharactersEditor extends StatelessWidget {
  final List<GroupCharacter> characters;
  final Function(List<GroupCharacter>) onChanged;
  final ChatType chatType;

  const GroupCharactersEditor({
    super.key,
    required this.characters,
    required this.onChanged,
    required this.chatType,
  });

  @override
  Widget build(BuildContext context) {
    if (chatType != ChatType.group) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '群聊角色',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 2,
              ),
            ),
            if (characters.length < 5)
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => _showAddCharacterDialog(context),
              ),
          ],
        ),
        if (characters.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: const Text(
              '点击右上角添加群聊角色（最多5个）',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                ),
                child: ListTile(
                  leading: character.avatarBase64 != null
                      ? ClipOval(
                          child: ImageService.imageFromBase64String(
                            character.avatarBase64!,
                            width: 40,
                            height: 40,
                          ),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                  title: Text(
                    character.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    character.setting,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.white70),
                    onPressed: () {
                      final newCharacters =
                          List<GroupCharacter>.from(characters);
                      newCharacters.removeAt(index);
                      onChanged(newCharacters);
                    },
                  ),
                  onTap: () => _showAddCharacterDialog(
                    context,
                    editIndex: index,
                    character: character,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _showAddCharacterDialog(
    BuildContext context, {
    int? editIndex,
    GroupCharacter? character,
  }) async {
    final result = await Navigator.of(context).push<GroupCharacter>(
      MaterialPageRoute(
        builder: (context) => GroupCharacterEditPage(
          character: character,
        ),
      ),
    );

    if (result != null) {
      final newCharacters = List<GroupCharacter>.from(characters);
      if (editIndex != null) {
        newCharacters[editIndex] = result;
      } else {
        newCharacters.add(result);
      }
      onChanged(newCharacters);
    }
  }
}

class GroupCharacterEditPage extends StatefulWidget {
  final GroupCharacter? character;

  const GroupCharacterEditPage({
    super.key,
    this.character,
  });

  @override
  State<GroupCharacterEditPage> createState() => _GroupCharacterEditPageState();
}

class _GroupCharacterEditPageState extends State<GroupCharacterEditPage> {
  final _nameController = TextEditingController();
  final _settingController = TextEditingController();
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.character?.name ?? '';
    _settingController.text = widget.character?.setting ?? '';
    _avatarBase64 = widget.character?.avatarBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _settingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.character != null ? '编辑角色' : '添加角色',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_nameController.text.isEmpty ||
                    _settingController.text.isEmpty) {
                  CustomSnackBar.show(context, message: '请填写完整信息');
                  return;
                }
                Navigator.of(context).pop(
                  GroupCharacter(
                    avatarBase64: _avatarBase64,
                    name: _nameController.text,
                    setting: _settingController.text,
                  ),
                );
              },
              child: const Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final String base64String =
                      await ImageService.processAvatarImage(image.path);
                  setState(() {
                    _avatarBase64 = base64String;
                  });
                }
              },
              child: Center(
                child: _avatarBase64 != null
                    ? Stack(
                        children: [
                          ClipOval(
                            child: ImageService.imageFromBase64String(
                              _avatarBase64!,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '角色名称',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 2,
                  ),
                ),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '角色设定',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 2,
                  ),
                ),
                TextField(
                  controller: _settingController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
