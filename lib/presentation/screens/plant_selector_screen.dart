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
  bool _isLoadingMore = false;
  String? _searchError;
  int _currentPage = 1;
  int _totalPages = 1;

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
        _currentPage = 1;
        _totalPages = 1;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _searchError = null;
      _currentPage = 1;
      _totalPages = 1;
    });
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    try {
      final (:results, :totalPages) = await ref
          .read(plantCatalogRepositoryProvider)
          .searchSpecies(query.trim(), page: 1);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _totalPages = totalPages;
          _currentPage = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = 'No se pudo conectar con el servicio de plantas.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final (:results, totalPages: _) = await ref
          .read(plantCatalogRepositoryProvider)
          .searchSpecies(_searchController.text.trim(), page: nextPage);
      if (mounted) {
        setState(() {
          _searchResults = [..._searchResults, ...results];
          _currentPage = nextPage;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _selectLocalPlant(PlantProfile planta) async {
    final plantRepo = ref.read(plantRepositoryProvider);
    await plantRepo.selectPlant(planta);
    if (mounted) {
      final c = AppColors.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${planta.emoji} Perfil ${planta.nombre} activado'),
          backgroundColor: c.success,
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
            final c = AppColors.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🌱 ${plant.nombre} activado'),
                backgroundColor: c.success,
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
              final c = AppColors.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Planta guardada en tu catálogo'),
                  backgroundColor: c.success,
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              final c = AppColors.of(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Error al guardar planta'),
                  backgroundColor: c.error,
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
    final c = AppColors.of(context);
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
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar planta...',
                hintStyle: TextStyle(color: c.textMuted),
                prefixIcon: Icon(Icons.search, color: c.textMuted),
                suffixIcon: _isSearchActive
                    ? IconButton(
                        icon: Icon(Icons.clear, color: c.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: c.cardBackground,
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
                    isLoadingMore: _isLoadingMore,
                    hasMore: _currentPage < _totalPages,
                    error: _searchError,
                    onTap: _openApiPlantSheet,
                    onLoadMore: _loadMore,
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
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final void Function(PerenualSpecies) onTap;
  final VoidCallback onLoadMore;

  const _SearchResultsBody({
    required this.results,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.onTap,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: c.primary));
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, color: c.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Text('Sin resultados', style: TextStyle(color: c.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: results.length + (hasMore || isLoadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == results.length) {
          // Pagination footer
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isLoadingMore
                ? Center(child: CircularProgressIndicator(color: c.primary))
                : Center(
                    child: OutlinedButton(
                      onPressed: onLoadMore,
                      child: const Text('Cargar más'),
                    ),
                  ),
          );
        }
        return _ApiSpeciesCard(
          species: results[i],
          onTap: () => onTap(results[i]),
        );
      },
    );
  }
}

class _ApiSpeciesCard extends StatelessWidget {
  final PerenualSpecies species;
  final VoidCallback onTap;

  const _ApiSpeciesCard({required this.species, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (species.scientificName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      species.scientificName.first,
                      style: TextStyle(
                        color: c.textMuted,
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
            Icon(Icons.chevron_right, color: c.textMuted),
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
    final c = AppColors.of(context);
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
                    c.success.withValues(alpha: 0.25),
                    c.success.withValues(alpha: 0.08),
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
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temp: ${planta.tempMin}–${planta.tempMax}°C',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                  Text(
                    'pH: ${planta.phMin}–${planta.phMax}',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                  Text(
                    'EC: ${planta.ecMin}–${planta.ecMax} mS/cm',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 24),
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
          _enriched = EnrichedPlantProfile(
            base: base,
            perenualId: widget.species.id,
          );
          _loadingEnriched = false;
        });
      }
    }
  }

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
    final c = AppColors.of(context);
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
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: c.textMuted.withValues(alpha: 0.4),
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            if (widget.species.scientificName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.species.scientificName.first,
                style: TextStyle(
                  color: c.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (_loadingEnriched)
              Center(child: CircularProgressIndicator(color: c.primary))
            else ...[
              // Description
              if (profile?.description != null) ...[
                _SheetSection(
                  title: 'Descripción',
                  child: Text(
                    profile!.description!,
                    style: TextStyle(color: c.textSecondary),
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

              // Quick care tips (from species detail fields)
              if (profile?.careTips.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _SheetSection(
                  title: 'Resumen de cuidados',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: profile!.careTips
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: TextStyle(color: c.primary)),
                                  Expanded(
                                    child: Text(
                                      t,
                                      style: TextStyle(color: c.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],

              // Detailed care guide sections (from /api/species-care-guide-list)
              if (profile?.careGuideSections.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                _SheetSection(
                  title: 'Guía de cuidados',
                  child: Column(
                    children: profile!.careGuideSections
                        .where((s) => s.description.isNotEmpty)
                        .map((s) => _CareGuideSection(section: s))
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
                  children: [
                    Icon(Icons.info_outline, color: c.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los umbrales son valores estándar. Ajústalos en Configuración.',
                        style: TextStyle(color: c.textMuted, fontSize: 12),
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

// ── Care guide section (expandable) ───────────────────────────────────────────

class _CareGuideSection extends StatelessWidget {
  final PerenualCareSection section;
  const _CareGuideSection({required this.section});

  static const _icons = <String, IconData>{
    'watering':    Icons.water_drop_outlined,
    'sunlight':    Icons.wb_sunny_outlined,
    'fertilizing': Icons.science_outlined,
    'pruning':     Icons.content_cut_outlined,
    'soil':        Icons.landscape_outlined,
    'pest':        Icons.bug_report_outlined,
  };

  static const _labels = <String, String>{
    'watering':    'Riego',
    'sunlight':    'Luz solar',
    'fertilizing': 'Fertilización',
    'pruning':     'Poda',
    'soil':        'Suelo',
    'pest':        'Plagas',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final type = section.type.toLowerCase();
    final icon = _icons[type] ?? Icons.eco_outlined;
    final label = _labels[type] ?? _capitalize(section.type);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: Icon(icon, color: c.primary, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: c.textMuted,
        collapsedIconColor: c.textMuted,
        children: [
          Text(
            section.description,
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
          Text(
            rec.notes,
            style: TextStyle(
              color: AppColors.of(context).textMuted,
              fontSize: 12,
            ),
          ),
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
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(
          color: c.textMuted,
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
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: c.textPrimary,
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
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: c.textMuted, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
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
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.primary,
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
    final c = AppColors.of(context);
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: c.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.eco, color: c.success, size: 32),
    );
  }
}
