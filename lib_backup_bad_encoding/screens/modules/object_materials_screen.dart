import 'package:flutter/material.dart';

import '../../models/object_material.dart';
import '../../services/materials_service.dart';

class ObjectMaterialsScreen extends StatefulWidget {
  final int objectId;
  final String objectName;

  const ObjectMaterialsScreen({
    super.key,
    required this.objectId,
    required this.objectName,
  });

  @override
  State<ObjectMaterialsScreen> createState() => _ObjectMaterialsScreenState();
}

class _ObjectMaterialsScreenState extends State<ObjectMaterialsScreen> {
  bool isLoading = true;
  bool canEdit = false;
  String? errorText;
  List<ObjectMaterial> materials = [];

  @override
  void initState() {
    super.initState();
    loadMaterials();
  }

  Future<void> loadMaterials() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final result = await MaterialsService.getMaterials(widget.objectId);

      if (!mounted) return;

      setState(() {
        materials = result['materials'] as List<ObjectMaterial>;
        canEdit = result['can_edit'] == true;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorText = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  double get totalSum {
    return materials.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.price),
    );
  }

  String money(double value) {
    return value.toStringAsFixed(2);
  }

  Future<void> deleteMaterial(ObjectMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('РЈРґР°Р»РёС‚СЊ РјР°С‚РµСЂРёР°Р»?'),
          content: Text('РЈРґР°Р»РёС‚СЊ "${material.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('РћС‚РјРµРЅР°'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('РЈРґР°Р»РёС‚СЊ'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await MaterialsService.deleteMaterial(
        objectId: widget.objectId,
        materialId: material.id,
      );

      await loadMaterials();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('РњР°С‚РµСЂРёР°Р» СѓРґР°Р»С‘РЅ')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'РќРµ СѓРґР°Р»РѕСЃСЊ СѓРґР°Р»РёС‚СЊ: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> showMaterialDialog({ObjectMaterial? material}) async {
    final isEdit = material != null;

    final nameController = TextEditingController(text: material?.name ?? '');
    final unitController = TextEditingController(text: material?.unit ?? '');
    final quantityController = TextEditingController(
      text: material == null ? '' : material.quantity.toString(),
    );
    final priceController = TextEditingController(
      text: material == null ? '' : material.price.toString(),
    );
    final commentController = TextEditingController(
      text: material?.comment ?? '',
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> save() async {
              final name = nameController.text.trim();
              final unit = unitController.text.trim();
              final comment = commentController.text.trim();
              final quantity = double.tryParse(
                    quantityController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;
              final price = double.tryParse(
                    priceController.text.trim().replaceAll(',', '.'),
                  ) ??
                  0;

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Р’РІРµРґРё РЅР°Р·РІР°РЅРёРµ РјР°С‚РµСЂРёР°Р»Р°')),
                );
                return;
              }

              setSheetState(() {
                isSaving = true;
              });

              try {
                if (isEdit) {
                  await MaterialsService.updateMaterial(
                    objectId: widget.objectId,
                    materialId: material.id,
                    name: name,
                    unit: unit.isEmpty ? null : unit,
                    quantity: quantity,
                    price: price,
                    comment: comment.isEmpty ? null : comment,
                  );
                } else {
                  await MaterialsService.createMaterial(
                    objectId: widget.objectId,
                    name: name,
                    unit: unit.isEmpty ? null : unit,
                    quantity: quantity,
                    price: price,
                    comment: comment.isEmpty ? null : comment,
                  );
                }

                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                setSheetState(() {
                  isSaving = false;
                });

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ РјР°С‚РµСЂРёР°Р»' : 'Р”РѕР±Р°РІРёС‚СЊ РјР°С‚РµСЂРёР°Р»',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'РќР°Р·РІР°РЅРёРµ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: unitController,
                          decoration: const InputDecoration(
                            labelText: 'Р•Рґ. РёР·Рј.',
                            hintText: 'РјРµС€, С€С‚, РјВІ, РєРі',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'РљРѕР»РёС‡РµСЃС‚РІРѕ',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Р¦РµРЅР°',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'РљРѕРјРјРµРЅС‚Р°СЂРёР№',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: isSaving ? null : save,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              isSaving
                                  ? 'РЎРѕС…СЂР°РЅСЏРµРј...'
                                  : isEdit
                                      ? 'РЎРѕС…СЂР°РЅРёС‚СЊ'
                                      : 'Р”РѕР±Р°РІРёС‚СЊ',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    unitController.dispose();
    quantityController.dispose();
    priceController.dispose();
    commentController.dispose();

    if (saved == true) {
      await loadMaterials();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'РњР°С‚РµСЂРёР°Р» РѕР±РЅРѕРІР»С‘РЅ' : 'РњР°С‚РµСЂРёР°Р» РґРѕР±Р°РІР»РµРЅ'),
        ),
      );
    }
  }

  Widget buildMaterialCard(ObjectMaterial material) {
    final sum = material.quantity * material.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1F6FEB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF1F6FEB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'РљРѕР»-РІРѕ: ${material.quantity} ${material.unit ?? ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  'Р¦РµРЅР°: ${money(material.price)} РіСЂРЅ',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  'РЎСѓРјРјР°: ${money(sum)} РіСЂРЅ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (material.comment != null && material.comment!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    material.comment!,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  showMaterialDialog(material: material);
                }

                if (value == 'delete') {
                  deleteMaterial(material);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ')),
                PopupMenuItem(value: 'delete', child: Text('РЈРґР°Р»РёС‚СЊ')),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorText != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 46, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                errorText!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: loadMaterials,
                icon: const Icon(Icons.refresh),
                label: const Text('РџРѕРІС‚РѕСЂРёС‚СЊ'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadMaterials,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F6FEB), Color(0xFF4C8DFF)],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.objectName,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'РњР°С‚РµСЂРёР°Р»С‹ РѕР±СЉРµРєС‚Р°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'РС‚РѕРіРѕ: ${money(totalSum)} РіСЂРЅ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (materials.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                canEdit
                    ? 'РњР°С‚РµСЂРёР°Р»РѕРІ РїРѕРєР° РЅРµС‚. РќР°Р¶РјРё вЂњР”РѕР±Р°РІРёС‚СЊвЂќ, С‡С‚РѕР±С‹ СЃРѕР·РґР°С‚СЊ РїРµСЂРІС‹Р№ РјР°С‚РµСЂРёР°Р».'
                    : 'РњР°С‚РµСЂРёР°Р»РѕРІ РїРѕРєР° РЅРµС‚.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            )
          else
            ...materials.map(buildMaterialCard),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'РњР°С‚РµСЂРёР°Р»С‹',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadMaterials,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: buildBody(),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => showMaterialDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Р”РѕР±Р°РІРёС‚СЊ'),
            )
          : null,
    );
  }
}



