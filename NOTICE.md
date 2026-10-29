Lunar source code is MIT licensed. Included imagery and reference data retain
their original status; the project license does not relicense NASA imagery.

The event formula organization in Astronomy.lua is adapted from the MIT-licensed
moonphase package by Sonia Keys, implementing Jean Meeus, Astronomical Algorithms
(2nd edition, 1998), chapter 49:
https://github.com/soniakeys/meeus/blob/master/v3/moonphase/moonphase.go

Copyright (c) 2013 Sonia Keys

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Moon images derive from the 2019 CGI Moon Kit color map, credited to
NASA's Scientific Visualization Studio / Ernie Wright, NASA/GSFC,
LRO / LROC / LOLA instrument teams. Credit is not endorsement.
https://svs.gsfc.nasa.gov/4720/
https://www.nasa.gov/nasa-brand-center/images-and-media/
The source JPEG is tools/lroc_color_poles_1k.jpg (SHA-256:
b246064f217f8d479df78c49c7c8595a8f5fbda008a72fd539978d2e121e0109).
The PNGs are derived orthographic renders, not NASA's original phase renders.

Test tables are US Naval Observatory public astronomical data. Raw responses
are preserved with provenance in tests/fixtures/README.md. No USNO service is
contacted by the widget or by routine tests.

Development-only npm dependencies and their transitive license notices are
installed by npm from package-lock.json; none is included in a skin release.
