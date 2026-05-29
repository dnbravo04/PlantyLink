import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/api/perenual_models.dart';
import '../../models/agronomic/enriched_plant_profile.dart';
import '../../models/agronomic/growth_stage.dart';
import '../../models/agronomic/nutrient_recommendation.dart';
import '../../models/plant_profile.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/app_card.dart';

class PlantSelectorScreen extends ConsumerStatefulWidget {
  const PlantSelectorScreen({super.key});

  @override
  ConsumerState<PlantSelectorScreen> createState() =>
      _PlantSelectorScreenState();
}

class _PlantSelectorScreenState extends ConsumerState<PlantSelectorScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<PerenualSpecies> _searchResults = [];
  bool _isLoading = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _searchError = null;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _searchError = null;
    });
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final results = await ref
          .read(plantCatalogRepositoryProvider)
          .searchSpecies(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'No se pudo conectar con Perenual API.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectLocalPlant(PlantProfile planta) async {
    final plantRepo = ref.read(plantRepositoryProvider);
    await plantRepo.selectPlant(planta);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${planta.emoji} Perfil ${planta.nombre} activado'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _openApiPlantSheet(PerenualSpecies species) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApiPlantDetailSheet(
        species: species,
        onSelect: (plant, perenualId) async {
          Navigator.pop(context); // close sheet
          await ref
              .read(plantRepositoryProvider)
              .selectPlant(plant);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🌱 ${plant.nombre} activado'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // close selector
          }
        },
        onSave: (plant, perenualId) async {
          try {
            await ref
                .read(plantCatalogRepositoryProvider)
                .saveToUserCatalog(plant, perenualId: perenualId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Planta guardada en tu catálogo'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al guardar planta'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  bool get _isSearchActive => _searchController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final localPlants = ref.read(plantRepositoryProvider).availablePlants;
    final userCatalogAsync = ref.watch(userCatalogStreamProvider);

    return AppScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Mis Plantas'),
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar en Perenual API...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _isSearchActive
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _isSearchActive
                ? _SearchResultsBody(
                    results: _searchResults,
                    isLoading: _isLoading,
                    error: _searchError,
                    onTap: _openApiPlantSheet,
                  )
                : _LocalCatalogBody(
                    localPlants: localPlants,
                    userCatalogAsync: userCatalogAsync,
                    onSelectLocal: _selectLocalPlant,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Search results ─────────────────────────────────────────────────────────────

class _SearchResultsBody extends StatelessWidget {
  final List<PerenualSpecies> results;
  final bool isLoading;
  final String? error;
  final void Function(PerenualSpecies) onTap;

  const _SearchResultsBody({
    required this.results,
    required this.isLoading,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Sin resultados',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: results.length,
      itemBuilder: (_, i) => _ApiSpeciesCard(
        species: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}

class _ApiSpeciesCard extends StatelessWidget {
  final PerenualSpecies species;
  final VoidCallback onTap;

  const _ApiSpeciesCard({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final thumb = species.defaultImage?.thumbnail;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumb != null && thumb.isNotEmpty
                  ? Image.network(
                      thumb,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _PlantIconBox(),
                    )
                  : _PlantIconBox(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.commonName.isEmpty ? 'Sin nombre' : species.commonName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (species.scientificName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      species.scientificName.first,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (species.cycle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _Chip(species.cycle),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Local catalog ──────────────────────────────────────────────────────────────

class _LocalCatalogBody extends StatelessWidget {
  final List<PlantProfile> localPlants;
  final AsyncValue<List<PlantProfile>> userCatalogAsync;
  final Future<void> Function(PlantProfile) onSelectLocal;

  const _LocalCatalogBody({
    required this.localPlants,
    required this.userCatalogAsync,
    required this.onSelectLocal,
  });

  @override
  Widget build(BuildContext context) {
    final userPlants = userCatalogAsync.value ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        _SectionHeader('Catálogo local'),
        ...localPlants.map(
          (p) => _LocalPlantCard(planta: p, onTap: () => onSelectLocal(p)),
        ),
        if (userPlants.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionHeader('Mi catálogo'),
          ...userPlants.map(
            (p) => _LocalPlantCard(planta: p, onTap: () => onSelectLocal(p)),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LocalPlantCard extends StatelessWidget {
  final PlantProfile planta;
  final VoidCallback onTap;

  const _LocalPlantCard({required this.planta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.3),
                    Colors.green.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(planta.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planta.nombre,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temp: ${planta.tempMin}–${planta.tempMax}°C',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Text(
                    'pH: ${planta.phMin}–${planta.phMax}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  Text(
                    'EC: ${planta.ecMin}–${planta.ecMax} mS/cm',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── API plant detail bottom sheet ──────────────────────────────────────────────

class _ApiPlantDetailSheet extends ConsumerStatefulWidget {
  final PerenualSpecies species;
  final Future<void> Function(PlantProfile plant, int perenualId) onSelect;
  final Future<void> Function(PlantProfile plant, int perenualId) onSave;

  const _ApiPlantDetailSheet({
    required this.species,
    required this.onSelect,
    required this.onSave,
  });

  @override
  ConsumerState<_ApiPlantDetailSheet> createState() =>
      _ApiPlantDetailSheetState();
}

class _ApiPlantDetailSheetState extends ConsumerState<_ApiPlantDetailSheet> {
  EnrichedPlantProfile? _enriched;
  bool _loadingEnriched = true;

  @override
  void initState() {
    super.initState();
    _loadEnriched();
  }

  Future<void> _loadEnriched() async {
    final base = _buildBaseProfile();
    try {
      final enriched = await ref
          .read(plantCatalogRepositoryProvider)
          .getEnrichedProfile(base, perenualId: widget.species.id);
      if (mounted) {
        setState(() {
          _enriched = enriched;
          _loadingEnriched = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _enriched = EnrichedPlantProfile(base: base, perenualId: widget.species.id);
          _loadingEnriched = false;
        });
      }
    }
  }

  /// Build a generic [PlantProfile] from the Perenual species summary.
  /// Thresholds use standard hydroponic defaults; users can adjust in Settings.
  PlantProfile _buildBaseProfile() {
    final name = widget.species.commonName.isNotEmpty
        ? widget.species.commonName
        : widget.species.scientificName.firstOrNull ?? 'Planta desconocida';
    return PlantProfile(
      nombre: name,
      emoji: '🌱',
      tempMin: 18,
      tempMax: 28,
      phMin: 5.5,
      phMax: 6.5,
      ecMin: 1.0,
      ecMax: 2.5,
      nivelAguaMin: 20.0,
      nivelFertilizanteMin: 20.0,
      fuente: 'Perenual API (id: ${widget.species.id})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _enriched;
    final base = profile?.base ?? _buildBaseProfile();
    final rec = profile != null
        ? ref
            .read(agronomicServiceProvider)
            .recommendDosing(base, GrowthStage.vegetative)
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header image + title
            if (widget.species.defaultImage?.mediumUrl.isNotEmpty == true) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.species.defaultImage!.mediumUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              widget.species.commonName.isEmpty
                  ? 'Planta desconocida'
                  : widget.species.commonName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.species.scientificName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.species.scientificName.first,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (_loadingEnriched)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Description
              if (profile?.description != null) ...[
                _SheetSection(
                  title: 'Descripción',
                  child: Text(
                    profile!.description!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // API metadata chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (profile?.cycle != null) _Chip(profile!.cycle!),
                  if (profile?.growthRate != null)
                    _Chip('Crecimiento: ${profile!.growthRate!}'),
                  if (profile?.careLevel != null)
                    _Chip('Cuidado: ${profile!.careLevel!}'),
                ],
              ),

              if (profile?.careTips.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _SheetSection(
                  title: 'Consejos de cuidado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: profile!.careTips
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ',
                                      style: TextStyle(
                                          color: AppColors.primary)),
                                  Expanded(
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],

              // Nutrient recommendation
              if (rec != null) ...[
                const SizedBox(height: 16),
                _NutrientCard(rec: rec),
              ],

              // Hydroponic defaults notice
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.textMuted, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los umbrales son valores estándar. Ajústalos en Configuración.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Seleccionar como activo'),
              onPressed: () => widget.onSelect(base, widget.species.id),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Guardar en mi catálogo'),
              onPressed: () => widget.onSave(base, widget.species.id),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Nutrient card ──────────────────────────────────────────────────────────────

class _NutrientCard extends StatelessWidget {
  final NutrientRecommendation rec;

  const _NutrientCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return _SheetSection(
      title: 'Nutrición recomendada (${rec.stage.label})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('EC objetivo',
              '${rec.ecTargetMin.toStringAsFixed(1)}–${rec.ecTargetMax.toStringAsFixed(1)} mS/cm'),
          _InfoRow('pH objetivo',
              '${rec.phTargetMin.toStringAsFixed(1)}–${rec.phTargetMax.toStringAsFixed(1)}'),
          _InfoRow('Ratio N-P-K', rec.npkRatio),
          _InfoRow('Dosis', '${rec.doseMlPerLiter.toStringAsFixed(1)} mL/L'),
          const SizedBox(height: 6),
          Text(rec.notes,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Small shared widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PlantIconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.eco, color: Colors.green, size: 32),
    );
  }
}
