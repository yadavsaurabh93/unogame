import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color baseColor;
  final IconData icon;
  final double width;
  final bool isLoading;

  const ModernButton({
    super.key,
    required this.label,
    required this.onTap,
    this.baseColor = Colors.blue,
    required this.icon,
    this.width = 280,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: width,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLoading) Icon(icon, size: 24),
            SizedBox(width: isLoading ? 0 : 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 15),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              )
          ],
        ),
      ),
    );
  }
}
