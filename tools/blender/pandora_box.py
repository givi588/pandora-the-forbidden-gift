"""Build the chest in meters with the front facing Blender -Y."""

from math import cos, pi, sin, tau

from materials import box_palette
from shapes import bar, block, combine, cylinder


HINGE = (0.0, 0.23, 0.20)


def greek_key(parts, x, y, z, material, name):
    path = [(-0.059, -0.025), (-0.059, 0.025), (0.059, 0.025),
            (0.059, -0.025), (-0.026, -0.025), (-0.026, 0.005), (0.033, 0.005)]
    for index, (a, b) in enumerate(zip(path, path[1:])):
        start = (x + a[0], y, z + a[1])
        end = (x + b[0], y, z + b[1])
        parts.append(bar(f"{name}_{index:02}", start, end, 0.007, 0.006, material))


def lid_rosette(parts, palette):
    each_angle = tau / 8
    for index in range(8):
        a = each_angle * index
        start = (cos(a) * 0.021, -0.23 + sin(a) * 0.021, 0.064)
        end = (cos(a) * 0.062, -0.23 + sin(a) * 0.062, 0.064)
        parts.append(bar(f"RosettePetal_{index:02}", start, end, 0.009, 0.009, palette["gold"]))
    parts.append(cylinder("RosetteAmber", (0, -0.23, 0.067), 0.018, 0.012, palette["ember"]))


def build_pandora_box():
    m = box_palette()
    body = [
        block("BasePlate", (0, 0, -0.032), (0.636, 0.462, 0.031), m["bronze"], 0.009),
        block("WellFloor", (0, 0, -0.004), (0.566, 0.397, 0.028), m["dark"], 0.006),
        cylinder("InteriorSealSeat", (0, 0.105, 0.035), 0.059, 0.055, m["bronze"]),
        cylinder("InteriorSealRing", (0, 0.105, 0.066), 0.055, 0.012, m["gold"]),
        cylinder("InteriorAmber", (0, 0.105, 0.075), 0.039, 0.010, m["ember"]),
    ]
    for side in (-1, 1):
        label = "Left" if side < 0 else "Right"
        face = "Front" if side < 0 else "Rear"
        x, y = side * 0.284, side * 0.199
        body.extend([
            block(f"{label}Wall", (x, 0, 0.079), (0.049, 0.367, 0.168), m["bronze"], 0.007),
            block(f"{face}Wall", (0, y, 0.079), (0.609, 0.048, 0.168), m["bronze"], 0.009),
            block(f"{face}Enamel", (0, side * 0.223, 0.091), (0.542, 0.014, 0.086), m["patina"], 0.006),
            block(f"{label}Enamel", (side * 0.310, 0, 0.091), (0.014, 0.320, 0.086), m["patina"], 0.006),
        ])
        for level, height in (("Foot", 0.016), ("Rim", 0.154)):
            body.extend([
                block(f"{face}{level}", (0, side * 0.218, height), (0.638, 0.027, 0.022), m["gold"]),
                block(f"{label}{level}", (side * 0.306, 0, height), (0.022, 0.415, 0.022), m["gold"]),
            ])
        for end in (-1, 1):
            corner = f"{label}{'Back' if end > 0 else 'Front'}"
            body.append(block(f"{corner}Band", (side * 0.298, end * 0.206, 0.087),
                              (0.035, 0.038, 0.113), m["gold"], 0.005))
        greek_key(body, side * 0.160, -0.232, 0.090, m["gold"], f"{label}GreekKey")
        for index, inset in enumerate((-0.092, 0.0, 0.092)):
            width = 0.034 if inset == 0.0 else 0.018
            body.append(block(f"{label}SideDiamond_{index}", (side * 0.319, inset, 0.091),
                              (0.008, width, width), m["gold"], 0.002, (pi / 4, 0, 0)))
        body.append(cylinder(f"{label}HingePin", (side * 0.196, 0.232, 0.20), 0.018, 0.108,
                             m["gold"], (0, pi / 2, 0)))
        body.append(block(f"{label}HingeLeaf", (side * 0.196, 0.224, 0.170),
                          (0.077, 0.015, 0.066), m["bronze"], 0.005))

    body.extend([
        block("ClaspBacking", (0, -0.232, 0.104), (0.071, 0.016, 0.095), m["gold"], 0.008),
        cylinder("ClaspAmber", (0, -0.248, 0.107), 0.020, 0.013, m["ember"], (pi / 2, 0, 0)),
    ])

    cover = [
        block("LidCasting", (0, -0.23, 0.001), (0.670, 0.477, 0.063), m["bronze"], 0.013),
        block("GiltCrown", (0, -0.23, 0.030), (0.640, 0.446, 0.021), m["gold"], 0.006),
        block("EnamelInlay", (0, -0.23, 0.045), (0.590, 0.392, 0.026), m["patina"], 0.008),
        block("UndersidePanel", (0, -0.23, -0.032), (0.485, 0.352, 0.008), m["dark"], 0.003),
    ]
    for side in (-1, 1):
        label = "Left" if side < 0 else "Right"
        cover.extend([
            block(f"{label}LidRail", (side * 0.246, -0.23, 0.060), (0.014, 0.319, 0.010), m["gold"]),
            block(f"{label}LidLatch", (side * 0.195, -0.033, -0.014), (0.075, 0.072, 0.020), m["gold"], 0.004),
            block(f"{label}TopDiamond", (side * 0.137, -0.23, 0.060), (0.024, 0.024, 0.012),
                  m["gold"], 0.002, (0, 0, pi / 4)),
        ])
    for side in (-1, 1):
        name = "NearGiltRail" if side < 0 else "FarGiltRail"
        cover.append(block(name, (0, -0.23 + side * 0.157, 0.060), (0.494, 0.014, 0.010), m["gold"]))
    lid_rosette(cover, m)
    return combine("PandoraBoxBody", body), combine("PandoraBoxLid", cover)
