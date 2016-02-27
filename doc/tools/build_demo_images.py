#!/usr/bin/env python
#
#   For CoSMoMVPA's license terms and conditions, see   #
#   the COPYING file distributed with CoSMoMVPA         #
#
# builds gallery with demonstrations

import os
import math



class Image(object):
    def __init__(self, label, prefix, index):
        self.label = label
        self.prefix = prefix
        self.index = index

    def __str__(self):
        return '<%s>' % label

    def to_rst(self):
        image_scale = .3

        image_ref = self.get_image_ref()

        if image_ref is None:
            print('Not found: image %s (# %d)' % (self.prefix, self.index))

        rst = '.. |%s| image:: %s\n    :target: %s\n    :scale: %d%%\n' % (
            self.get_image_link(), image_ref,
            self.get_code_link(), image_scale * 100,)

        return rst

    def file_exists(self):
        return self.get_image_ref() is not None

    def get_image_ref(self):
        image_dir = '_static/publish'
        image_patterns = ('%s_%02d.png', '%s%d.png')
        relative_to_image_dir = '../source'

        root_dir = os.path.join(os.path.dirname(__file__),
                                relative_to_image_dir)

        for image_pattern in image_patterns:
            image_fn = image_pattern % (self.prefix, self.index)
            image_path_fn = os.path.join(root_dir, image_dir, image_fn)

            if os.path.exists(image_path_fn):
                image_ref = os.path.join(image_dir, image_fn)
                return image_ref

        return None

    def get_image_link(self):
        return 'gallery_%s_%d' % (self.prefix, self.index)

    def get_code_link(self):
        return 'matlab/%s.html' % self.prefix

    def get_rst_table_cell(self):
        image_link = self.get_image_link()
        label = self.label
        code_link = self.prefix

        return Cell.from_str(' |%s| \n\n :ref:`%s <%s>` ' % (image_link, label, code_link))



class Cell(object):
    def __init__(self, lines):
        max_length = 0 if len(lines) == 0 else max(len(line) for line in lines)

        add_padding = lambda x: x + (' ' * (max_length - len(x)))

        self.lines = [add_padding(line) for line in lines]

    @classmethod
    def from_str(cls, s):
        return cls(s.split('\n'))

    @property
    def width(self):
        return len(self.lines[0]) if len(self.lines) > 0 else 0

    @property
    def height(self):
        return len(self.lines)

    @property
    def shape(self):
        return (self.width, self.height)

    def fill_horizontally(self, count):
        padding = ' ' * (count - self.width)
        return Cell([line + padding for line in self.lines])

    def fill_vertically(self, count):
        padding = ' ' * self.width
        return Cell(self.lines + [padding] * (count - self.height))

    def add_horizontal(self, other):
        height = max((self.height, other.height))

        lines_s = self.fill_vertically(height).lines
        lines_o = other.fill_vertically(height).lines

        lines = [l_s + l_o for (l_s, l_o) in zip(lines_s, lines_o)]

        return Cell(lines)

    def transpose(self):
        return Cell(map(lambda x: ''.join(x), zip(*self.lines)))

    def add_vertical(self, other):
        self_tr = self.transpose()
        other_tr = other.transpose()

        both_tr = self_tr.add_horizontal(other_tr)

        return both_tr.transpose()

    def __str__(self):
        return '\n'.join(self.lines)

    def __repr__(self):
        return '%s@%dx%d' % (self.__class, self.height, self.width)

    @classmethod
    def tabelize(cls, cells, n_columns, hor_sep, ver_sep, edge_sep):
        n_cells = len(cells)

        if n_cells == 0:
            return cls([[]])

        n_rows = int(math.ceil(float(n_cells) / n_columns))

        n_missing = n_rows * n_columns - n_cells
        rect_cells = cells + [Cell.from_str(' ') for _ in xrange(n_missing)]

        max_height = max(cell.height for cell in cells)
        max_width = max(cell.width for cell in cells)

        filled_cells = [cell.fill_horizontally(
            max_width).fill_vertically(
            max_height)
                        for cell in rect_cells]

        edge = cls([edge_sep])
        hor = cls([hor_sep * max_width])
        ver = cls([ver_sep] * (max_height))

        ver_edge = ver.add_vertical(edge)
        hor_edge = hor.add_horizontal(edge)
        edge_hor_edge = edge.add_horizontal(hor_edge)

        rows = [filled_cells[i:(i + n_columns)] for i in xrange(0, n_cells, n_columns)]

        cell_table = cls([])
        for i, row in enumerate(rows):
            cell_row = cls([])
            for j, _ in enumerate(row):
                cell = row[j]

                cell = cell.add_vertical(hor)
                cell = cell.add_horizontal(ver_edge)

                if j == 0:
                    cell = ver_edge.add_horizontal(cell)

                if i == 0:
                    cell = (edge_hor_edge if j == 0 else hor_edge).add_vertical(cell)

                cell_row = cell_row.add_horizontal(cell)

            cell_table = cell_table.add_vertical(cell_row)

        return cell_table



class ImageCollection(object):
    def __init__(self):
        self.images = []

    def append(self, img):
        if img.file_exists():
            self.images.append(img)

    @classmethod
    def from_dict(cls, demos):
        c = cls()
        for label, (prefix, index) in demos.iteritems():
            img = Image(label, prefix, index)
            c.append(img)

        return c

    def __str__(self):
        return '%d images' % (len(self.images))

    def to_rst(self):
        if len(self) == 0:
            return ''

        header = 'Analysis gallery'
        header_rst = '%s\n%s' % (header, '=' * len(header))

        img_rst = ''.join(img.to_rst() for img in self.images)

        table_rst = self.get_rst_table()

        rst = '\n\n'.join((header_rst, img_rst, table_rst))
        return rst

    def get_rst_table(self, n_columns=4):
        cells = [image.get_rst_table_cell() for image in self.images]
        return str(Cell.tabelize(cells, n_columns=n_columns,
                                 hor_sep='-', ver_sep='|', edge_sep='+'))

    def __len__(self):
        return len(self.images)

    def write(self, fn=None):
        if fn is None:
            relative_fn = '../source/_static/demo_gallery.txt'
            fn = os.path.join(os.path.dirname(__file__),
                              relative_fn)

        with open(fn, 'w') as f:
            f.write(self.to_rst())



if __name__ == '__main__':
    demos = {'fMRI ROI classification analysis':
                 ('demo_fmri_rois', 8),
             'fMRI ROI split-half correlations':
                 ('run_splithalf_correlations', 5),
             'fMRI split-half correlations searchlight':
                 ('demo_fmri_correlation_searchlight', 1),
             'Surface-based classification searchlight':
                 ('demo_surface_searchlight_lda', 1),
             'Representational similarity analysis searchlight':
                 ('demo_fmri_searchlight_rsm', 2),
             'Fast Naive Bayes searchlight':
                 ('demo_fmri_searchlight_naive_bayes', 1),
             'DISTATIS':
                 ('demo_fmri_distatis', 1),
             'Threshold-Free Cluster Enhancement':
                 ('demo_surface_tfce', 2),
             'MEEG timeseries classification':
                 ('demo_meeg_timeseries_classification', 1),
             'MEEG time-locked searchlight':
                 ('demo_meeg_timelock_searchlight', 1),
             'MEEG time-frequency searchlight':
                 ('demo_meeg_timefreq_searchlight', 1),
             'MEEG time generalization':
                 ('demo_meeg_timeseries_generalization', 1),
             'MEEG time generalization searchlight':
                 ('demo_meeg_timeseries_generalization', 3)
             }

    c = ImageCollection.from_dict(demos)

    n_images = len(c)

    if n_images == 0:
        msg = ("No elements found for gallery. To build the gallery, "
               "run cosmo_publish_run_scripts from Matlab or GNU Octave")
    else:
        msg = "Found %d elements for gallery " % n_images

    print msg

    c.write()

