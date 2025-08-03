import 'package:flutter/material.dart';
import 'package:rapiruta_app/models/route_model.dart';

class RouteInfoPanel extends StatelessWidget {
  final RouteSolution foundSolution;
  final Animation<double> routeInfoAnimation;
  final bool routeInfoMinimized;
  final VoidCallback onToggle;

  const RouteInfoPanel({
    super.key,
    required this.foundSolution,
    required this.routeInfoAnimation,
    required this.routeInfoMinimized,
    required this.onToggle,
  });

  bool _hasTransfer() {
    int busSteps = foundSolution.steps
        .where((step) => step.type == StepType.bus)
        .length;
    return busSteps > 1;
  }

  Widget _buildTransferIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Icon(Icons.swap_horiz, size: 14, color: Colors.orange.shade700),
    );
  }

  Widget _buildBusInfo(RouteStep step, int stepIndex) {
    if (step.busColor == null) return const SizedBox.shrink();

    final textColor = step.busColor!.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    final bool isTransferStep =
        stepIndex > 0 &&
        foundSolution.steps[stepIndex - 1].type == StepType.walk &&
        foundSolution.steps
                .take(stepIndex)
                .where((s) => s.type == StepType.bus)
                .length >
            0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: step.busColor!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: step.busColor!.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: step.busColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: step.busColor!.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      step.vehicleIdentifier ?? '',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (isTransferStep)
                  Positioned(top: -6, right: -6, child: _buildTransferIcon()),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.companyName ?? 'Empresa Desconocida',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isTransferStep)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Transbordo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.instructions,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkInfo(RouteStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_walk,
              size: 18,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              step.instructions,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimizedPanel() {
    return GestureDetector(
      key: const ValueKey('minimized'),
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.route, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        '${(foundSolution.totalWalkingDistance / 1000).toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_hasTransfer()) ...[
                        const SizedBox(width: 8),
                        _buildTransferIcon(),
                      ],
                    ],
                  ),
                  Text(
                    '${foundSolution.steps.length} pasos',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_up, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(BuildContext context) {
    return Column(
      key: const ValueKey('expanded'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.route,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Tu Ruta',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_hasTransfer()) ...[
                          const SizedBox(width: 12),
                          _buildTransferIcon(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(foundSolution.totalWalkingDistance / 1000).toStringAsFixed(1)} km caminando',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: onToggle,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(horizontal: 24),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: foundSolution.steps.length,
              itemBuilder: (context, index) {
                final step = foundSolution.steps[index];
                if (step.type == StepType.bus) {
                  return _buildBusInfo(step, index);
                } else {
                  return _buildWalkInfo(step);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: ScaleTransition(
        scale: routeInfoAnimation,
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          constraints: BoxConstraints(
            maxHeight: routeInfoMinimized
                ? 80
                : MediaQuery.of(context).size.height * 0.45,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.vertical,
                  child: child,
                ),
              );
            },
            child: routeInfoMinimized
                ? _buildMinimizedPanel()
                : _buildExpandedPanel(context),
          ),
        ),
      ),
    );
  }
}
