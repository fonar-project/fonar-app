"""Uma vogal /a/ sintética, para o espectrograma de exemplo das prints.

Não é voz de ninguém: um trem de pulsos glóticos com f0 caindo de 210 a
195 Hz, filtrado por cinco formantes típicos do /a/. Gerado no próprio
Praat 6.1.38 (parselmouth), só para ilustrar a tela.
"""
import sys
import parselmouth
from parselmouth.praat import call

saida = sys.argv[1]
pitch = call("Create PitchTier", "f0", 0, 3)
for t, f in [(0, 210), (1.2, 204), (2.4, 198), (3, 195)]:
    call(pitch, "Add point", t, f)
pulsos = call(pitch, "To PointProcess")
fonte = call(pulsos, "To Sound (phonation)", 44100, 1.0, 0.05, 0.7, 0.03, 3.0, 4.0)
grade = call("Create FormantGrid", "a", 0, 3, 5, 800, 1000, 80, 40)
for i, (f, b) in enumerate([(800, 80), (1200, 90), (2500, 120), (3500, 150), (4500, 200)], start=1):
    call(grade, "Remove formant points between", i, 0, 3)
    call(grade, "Add formant point", i, 1.5, f)
    call(grade, "Remove bandwidth points between", i, 0, 3)
    call(grade, "Add bandwidth point", i, 1.5, b)
vogal = call([fonte, grade], "Filter")
call(vogal, "Scale peak", 0.8)
call(vogal, "Save as WAV file", saida)
print("ok", saida)
