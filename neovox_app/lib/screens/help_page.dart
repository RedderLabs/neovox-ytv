import 'package:flutter/material.dart';
import '../theme/cyber_theme.dart';
import '../widgets/scanlines_widget.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // How to create a playlist
          _buildSection(
            icon: Icons.playlist_add_rounded,
            title: 'CREAR UNA PLAYLIST EN YOUTUBE',
            steps: const [
              _Step('1', 'Abre YouTube en tu navegador o la app movil'),
              _Step('2', 'Inicia sesion en tu cuenta de Google'),
              _Step('3', 'Busca un video que quieras anadir'),
              _Step('4', 'Toca el boton "Guardar" debajo del video'),
              _Step('5', 'Selecciona "Crear nueva playlist"'),
              _Step('6', 'Ponle un nombre y asegurate de que la visibilidad sea "Publica" o "Sin listar"'),
              _Step('7', 'Repite con mas videos para llenar tu playlist'),
            ],
          ),
          const SizedBox(height: 12),

          // How to get the URL
          _buildSection(
            icon: Icons.link_rounded,
            title: 'OBTENER LA URL DE TU PLAYLIST',
            steps: const [
              _Step('1', 'Ve a tu Biblioteca en YouTube'),
              _Step('2', 'Abre la playlist que quieres anadir'),
              _Step('3', 'Toca el boton "Compartir" (icono de flecha)'),
              _Step('4', 'Copia el enlace. Debe contener "list=" seguido de un codigo'),
              _Step('!', 'Ejemplo: https://youtube.com/playlist?list=PLxxxxxxxx'),
            ],
          ),
          const SizedBox(height: 12),

          // How to add it to NEOVOX
          _buildSection(
            icon: Icons.add_circle_outline_rounded,
            title: 'ANADIR A NEOVOX',
            steps: const [
              _Step('1', 'Ve a la pestana VAULT en la barra inferior'),
              _Step('2', 'Pulsa "+ ANADIR PLAYLIST"'),
              _Step('3', 'Escribe un nombre para tu playlist'),
              _Step('4', 'Pega la URL de YouTube que copiaste'),
              _Step('5', 'Pulsa ANADIR y listo!'),
            ],
          ),
          const SizedBox(height: 12),

          // Tips
          _buildSection(
            icon: Icons.tips_and_updates_rounded,
            title: 'CONSEJOS',
            steps: const [
              _Step('>', 'Las playlists PRIVADAS no funcionan. Usa "Publica" o "Sin listar"'),
              _Step('>', 'Puedes tener hasta 20 playlists en tu vault'),
              _Step('>', 'Arrastra la aguja del tocadiscos para hacer seek'),
              _Step('>', 'Tu numero de cuenta es tu unica llave. Guardalo bien'),
              _Step('>', 'Puedes cambiar la velocidad de reproduccion (0.5x - 2x)'),
            ],
          ),
          const SizedBox(height: 12),

          // FAQ
          _buildSection(
            icon: Icons.quiz_rounded,
            title: 'PREGUNTAS FRECUENTES',
            steps: const [
              _Step('?', 'No suena el audio: Asegurate de que el volumen no este en 0 y que la playlist sea publica'),
              _Step('?', 'Playlist vacia: La playlist puede ser privada o no tener videos disponibles'),
              _Step('?', 'Perdi mi cuenta: No hay forma de recuperarla. Crea una nueva y vuelve a anadir tus playlists'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<_Step> steps,
  }) {
    return Container(
      decoration: CyberTheme.panelDecoration,
      child: Stack(
        children: [
          const ScanlinesOverlay(),
          const CornerAccents(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: CT.accentGlow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title, style: CyberTheme.orbitron.copyWith(
                        fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2, color: CT.textHeader)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...steps.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: s.num == '!' || s.num == '>' || s.num == '?'
                              ? CT.authWarningBg
                              : CT.plBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: s.num == '!' || s.num == '>' || s.num == '?'
                              ? CT.authWarningBorder
                              : CT.plBadgeBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.num,
                          style: CyberTheme.orbitron.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: s.num == '!' ? CT.accentGlow
                                : s.num == '>' ? CT.accent
                                : s.num == '?' ? CT.accentGlow
                                : CT.plBadgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            s.text,
                            style: CyberTheme.mono.copyWith(
                              fontSize: 12, letterSpacing: 0.5, color: CT.textPrimary, height: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String num;
  final String text;
  const _Step(this.num, this.text);
}
