import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/portfolio_provider.dart';

class AllocationChart extends StatelessWidget {
  const AllocationChart({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PortfolioProvider>(context, listen: false);

    final symbols = provider.symbols;
    final weightList = provider.weights;

    if (symbols.isEmpty) {
      return const Center(child: Text("자산 배분 정보가 없습니다."));
    }

    final weights = <String, double>{};
    for (int i = 0; i < symbols.length; i++) {
      weights[symbols[i]] = weightList[i];
    }

    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.cyan
    ];

    int idx = 0;
    weights.forEach((symbol, weight) {
      sections.add(
        PieChartSectionData(
          value: weight * 100,
          title: '${(weight * 100).toStringAsFixed(1)}%',
          color: colors[idx % colors.length],
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
      idx++;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                '자산 배분',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 4,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: weights.entries.map((e) {
                  final index = weights.keys.toList().indexOf(e.key);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors[index % colors.length],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${e.key}  •  ${(e.value * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      ),
    );
  }
}
