/* sim_rev.h: simulator revisions and current rev level

   Copyright (c) 1993-2012, Robert M Supnik

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
   ROBERT M SUPNIK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

   Except as contained in this notice, the name of Robert M Supnik shall not be
   used in advertising or otherwise to promote the sale, use or other dealings
   in this Software without prior written authorization from Robert M Supnik.
*/

#ifndef SIM_REV_H_
#define SIM_REV_H_     0

#ifndef SIM_MAJOR
#define SIM_MAJOR       1
#endif
#ifndef SIM_MINOR
#define SIM_MINOR       0
#endif
#ifndef SIM_PATCH
#define SIM_PATCH       0
#endif
#ifndef SIM_DELTA
#define SIM_DELTA       0
#endif

#ifndef SIM_VERSION_MODE
#define SIM_VERSION_MODE "Current"
#endif

#if defined(SIM_NEED_GIT_COMMIT_ID)
#include ".git-commit-id.h"
#endif

/*
  Simh's git commit id would be undefined when working with an 
  extracted archive (zip file or tar ball).  To address this 
  problem and record the commit id that the archive was created 
  from, the archive creation process populates the below 
  information as a consequence of the "sim_rev.h export-subst" 
  line in the .gitattributes file.
 */
#define SIM_ARCHIVE_GIT_COMMIT_ID $Format:%H$
#define SIM_ARCHIVE_GIT_COMMIT_TIME $Format:%aI$

#endif
