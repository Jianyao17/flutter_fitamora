import 'package:flutter/material.dart';

class HasilDeteksi extends StatefulWidget {
  const HasilDeteksi({super.key});

  @override
  State<HasilDeteksi> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<HasilDeteksi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [Text("Hasil Deteksi", style: TextStyle(fontWeight: FontWeight.bold)), Text("Rekomendasi Latihan")],
        ),
      ),
    );
  }
}

// class HasilDeteksi extends StatefulWidget {
//   @override
//   _HasilDeteksiState createState() => _HasilDeteksiState();
// }

// class _HasilDeteksiState extends State<HasilDeteksi> {
//   List<Map<String, String>> exerciseRecommendations = [
//     {
//       'day': 'Day 1',
//       'exercise': 'Jumping Jacks',
//       'duration': '3x1 menit',
//     },
//     {
//       'day': 'Day 2',
//       'exercise': 'Y Pose',
//       'duration': '3x1 menit',
//     },
//     {
//       'day': 'Day 3',
//       'exercise': 'Cow Curls',
//       'duration': '3x1 menit',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () {
//             // Handle back navigation
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.home_outlined, color: Colors.black),
//             onPressed: () {
//               // Handle home navigation
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Detection Success Card
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(20.0),
//               decoration: BoxDecoration(
//                 color: Colors.amber[400],
//                 borderRadius: BorderRadius.circular(16.0),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 8.0,
//                     offset: Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Deteksi Postur Berhasil!',
//                     style: TextStyle(
//                       fontSize: 22.0,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   SizedBox(height: 8.0),
//                   Text(
//                     'Anda memiliki permasalahan .... pada postur anda',
//                     style: TextStyle(
//                       fontSize: 16.0,
//                       color: Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             SizedBox(height: 24.0),
            
//             // Exercise Recommendations Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Rekomendasi Latihan',
//                   style: TextStyle(
//                     fontSize: 20.0,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     // Handle set training
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[600],
//                     foregroundColor: Colors.white,
//                     padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20.0),
//                     ),
//                   ),
//                   child: Text(
//                     'Set Latihan',
//                     style: TextStyle(
//                       fontSize: 14.0,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
            
//             SizedBox(height: 16.0),
            
//             // Exercise Cards
//             ListView.builder(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: exerciseRecommendations.length,
//               itemBuilder: (context, index) {
//                 final exercise = exerciseRecommendations[index];
//                 return Container(
//                   margin: EdgeInsets.only(bottom: 12.0),
//                   padding: EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.amber[300],
//                     borderRadius: BorderRadius.circular(12.0),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.05),
//                         blurRadius: 4.0,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         exercise['day']!,
//                         style: TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       SizedBox(height: 12.0),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             flex: 2,
//                             child: Text(
//                               exercise['exercise']!,
//                               style: TextStyle(
//                                 fontSize: 16.0,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Text(
//                               exercise['duration']!,
//                               style: TextStyle(
//                                 fontSize: 14.0,
//                                 color: Colors.black87,
//                               ),
//                               textAlign: TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 12.0),
//                       // Placeholder dots for additional info
//                       Row(
//                         children: [
//                           Text('...', style: TextStyle(color: Colors.black54)),
//                           Spacer(),
//                           Text('...', style: TextStyle(color: Colors.black54)),
//                         ],
//                       ),
//                       SizedBox(height: 4.0),
//                       Row(
//                         children: [
//                           Text('...', style: TextStyle(color: Colors.black54)),
//                           Spacer(),
//                           Text('...', style: TextStyle(color: Colors.black54)),
//                         ],
//                       ),
//                       SizedBox(height: 4.0),
//                       Row(
//                         children: [
//                           Text('...', style: TextStyle(color: Colors.black54)),
//                           Spacer(),
//                           Text('...', style: TextStyle(color: Colors.black54)),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }