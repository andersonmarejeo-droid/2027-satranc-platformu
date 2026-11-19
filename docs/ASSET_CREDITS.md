# Third-party board assets

School/institution data added in 0.7.2: [dalgali/MEB-okul-listesi](https://github.com/dalgali/MEB-okul-listesi), snapshot 2026-08-31, commit `0f2b3e6af008f283c1f9b43bdcbd1556eab8da1f`, repository MIT license retained in `assets/data/schools/LICENSE.txt`. Source MEB data reuse permission has not been established; review was deferred by the user. See [SCHOOL_CATALOG.md](SCHOOL_CATALOG.md).

These assets ship offline with the application. No Poly Haven API request is made by the app.

Private-school names, provinces, districts and types were additionally collected from the public [MEB private-school directory](https://ookgm.meb.gov.tr/kurumlar.php) on 2026-10-04, following each province's displayed pagination. The 81 province totals were verified; one exact duplicate among 12,620 rows was removed, leaving 12,619 private schools. This source is not covered by the GitHub repository's MIT license. MEB reuse permission remains unverified and review was deferred by the user. Phones and addresses are not bundled; an address fingerprint distinguishes same-name campuses when constructing app IDs. Metadata is in `assets/data/schools/PRIVATE_SOURCE.json`.

| Asset | Author / source | License | Bundled use |
| --- | --- | --- | --- |
| [Chess Set](https://polyhaven.com/a/chess_set) | Riley Queen / Poly Haven | [CC0](https://polyhaven.com/license) | Six unique white-piece geometries simplified to a mobile mesh; both teams use the app's own palettes. |
| [Natural Walnut Veneer](https://polyhaven.com/a/natural_walnut_veneer) | Jenelle van Heerden / Poly Haven | CC0 | Original 1K diffuse JPEG, Usta Cevizi board. |
| [Marble 01](https://polyhaven.com/a/marble_01) | Rob Tuytel / Poly Haven | CC0 | Original 1K diffuse JPEG, Krem Mermer board. |

Downloaded 2026-10-03 from the official asset download manifests with a descriptive User-Agent. Only original asset files are used, not website preview renders.

Source file checksums (MD5 from the publisher's manifests):

- `chess_set_1k.gltf`: `ceac1016348f797f3db112e3e70a96a4`
- `chess_set.bin`: `815ae6d5becbcdd836b29b0d644bba95`
- `natural_walnut_veneer_diff_1k.jpg`: `b9dd8a10990c388322b2b2ca15824b8a`
- `marble_01_diff_1k.jpg`: `04325ced5018eb8a2e598a4ef69cb176`

Rebuild mobile geometry with `python tool/import_chess_mesh.py` after placing the verified glTF and BIN under `.dart_tool/asset-sources/chess-set/`. Vertex clustering at 0.06 board-square units preserves normals at hard edges, drops duplicate/degenerate triangles, and scales the king to 1.25 board-square units. The binary is 191,897 bytes; 10,805 triangles across six unique pieces. Source UV/material textures, normal maps and PBR roughness are not used; the app applies its existing lighting and color palettes. This is a Flutter-rendered 3D board, not a Unity or Unreal runtime.
