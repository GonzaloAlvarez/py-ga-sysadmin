import os
import tempfile
import mimetypes
from lib.encryption.aespcrypt import AESPCrypt
from lib.fmd.decorators import DependsOn, Action, GetStage
from lib.fmd.namedentity import NamedEntity
from lib.exceptions.workflow import EntryException, StageException

@Action(GetStage.RETRIEVING)
@DependsOn('deflate')
def settle(context, data):
    if not context.dest:
        context.dest = tempfile.mkdtemp()
    if 'record' in data:
        record = data['record']
        if context.fidlist:
            fileext = mimetypes.guess_extension(record['mime'], False)
            if fileext in ('.jpe', '.jpeg'):
                fileext = ".jpg"
            context.basename = context.fid + fileext
        else:
            if 'filename_history' in record and len(record['filename_history']) > 0 and 'basename' in record['filename_history'][0]:
                context.basename = record['filename_history'][0]['basename']
    if not context.basename:
        raise EntryException('Original filename not properly stored. File "%s" not downloaded' % context.fid)
    destfile = os.path.join(context.dest, context.basename)
    if os.path.isfile(destfile):
        raise EntryException('File "%s" already exists in destination. Skipping.' % destfile)
    if not os.path.isfile(context.filename):
        raise EntryException('Something went wrong with the downloaded file "%s"' % context.filename)
    
    os.rename(context.filename, destfile)

    context.filename = destfile
    return context.filename
