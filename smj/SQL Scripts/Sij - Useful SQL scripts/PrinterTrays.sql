  --TO SET THE TRAYS FOR A NEW PRINTER - PUT THE PRINTER NAME IN
  INSERT INTO PrinterSetting
  SELECT '', 'Tray2', 0, 'SMJ', GETDATE(), 'TRAYHEAD'
  
  INSERT INTO PrinterSetting
  SELECT '', 'Tray3', 0, 'SMJ', GETDATE(), 'TRAYCREAM'  
  
  INSERT INTO PrinterSetting
  SELECT '', 'Tray4', 0, 'SMJ', GETDATE(), 'TRAYPLAIN'   