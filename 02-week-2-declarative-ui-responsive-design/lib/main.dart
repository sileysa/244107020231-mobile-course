import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const kWideBreakpoint = 700.0;

void main() {
runApp(const AcademicOverviewApp());
}

class AcademicOverviewApp extends StatefulWidget {
const AcademicOverviewApp({super.key});

@override
State<AcademicOverviewApp> createState() => _AcademicOverviewAppState();
}

class _AcademicOverviewAppState extends State<AcademicOverviewApp> {
bool isDark = false;

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,

  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.light,
  ),

  darkTheme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: Colors.indigo,
    brightness: Brightness.dark,
  ),

  themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

  home: AcademicOverviewPage(
    isDark: isDark,
    onDarkChanged: (value) {
      setState(() {
        isDark = value;
      });
    },
  ),
);

}
}

class AcademicOverviewPage extends StatelessWidget {
const AcademicOverviewPage({
required this.isDark,
required this.onDarkChanged,
super.key,
});

final bool isDark;
final ValueChanged<bool> onDarkChanged;

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Academic Overview'),
actions: [
Semantics(
label: 'Ganti tema gelap',
child: Row(
children: [
Icon(
isDark ? Icons.dark_mode : Icons.light_mode,
),
const SizedBox(width: 4),
CupertinoSwitch(
value: isDark,
onChanged: onDarkChanged,
),
const SizedBox(width: 12),
],
),
),
],
),

  body: LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= kWideBreakpoint ? 2 : 1;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),

            const SizedBox(height: 24),

            GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

              children: const [
                InfoCard(
                  title: 'Assignments',
                  value: '8',
                ),
                InfoCard(
                  title: 'Attendance',
                  value: '98%',
                ),
                InfoCard(
                  title: 'GPA',
                  value: '3.98',
                ),
                InfoCard(
                  title: 'Current Week',
                  value: '02',
                ),
              ],
            ),
          ],
        ),
      );
    },
  ),
);

}

Widget _buildProfileHeader(BuildContext context) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Theme.of(context).colorScheme.primaryContainer,
borderRadius: BorderRadius.circular(16),
),
child: Row(
children: [
Semantics(
label: 'Foto profil mahasiswa',
child: CircleAvatar(
radius: 32,
backgroundColor:
Theme.of(context).colorScheme.primary,
child: Icon(
Icons.person,
size: 36,
color:
Theme.of(context).colorScheme.onPrimary,
),
),
),

      const SizedBox(width: 16),

      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sileysa Faedatul Nuraini',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 4),

            Text(
              'Mahasiswa Teknik Informatika',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),

            const SizedBox(height: 4),

            Text(
              'Semester 5',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
        ),
      ),
    ],
  ),
);

}
}

class InfoCard extends StatelessWidget {
const InfoCard({
required this.title,
required this.value,
super.key,
});

final String title;
final String value;

@override
Widget build(BuildContext context) {
final colorScheme = Theme.of(context).colorScheme;

return Card(
  child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            label: '$title: $value',
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
          ),
        ),

        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    ),
  ),
);

}
}