//---------------------------------------------------------------------------

#include <vcl.h>
#pragma hdrstop

#include "PmDBGrid.h"
#pragma package(smart_init)
//---------------------------------------------------------------------------
// ValidCtrCheck is used to assure that the components created do not have
// any pure virtual functions.
//

static inline void ValidCtrCheck(TPmDBGrid *)
{
  new TPmDBGrid(NULL);
}
//---------------------------------------------------------------------------
__fastcall TPmDBGrid::TPmDBGrid(TComponent* Owner)
  : TDBGrid(Owner)
{

}
//---------------------------------------------------------------------------
namespace Pmdbgrid
{
  void __fastcall PACKAGE Register()
  {
     TComponentClass classes[1] = {__classid(TPmDBGrid)};
     RegisterComponents("Data Controls", classes, 0);
  }
}
//---------------------------------------------------------------------------
 