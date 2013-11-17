CREATE TABLE mesaje (
  id_mesaj int(50) unsigned NOT NULL auto_increment,
  id_topic int(50) unsigned NOT NULL default '0',
  id_user int(50) unsigned NOT NULL default '0',
  continut longtext NOT NULL,
  data datetime NOT NULL default '0000-00-00 00:00:00',
  lastpost datetime NOT NULL default '0000-00-00 00:00:00',
  titlu text NOT NULL,
  PRIMARY KEY  (id_mesaj)
) TYPE=MyISAM;

CREATE TABLE reply (
  id_reply int(50) unsigned NOT NULL auto_increment,
  id_mesaj int(50) unsigned NOT NULL default '0',
  id_user int(50) unsigned NOT NULL default '0',
  continut longtext NOT NULL,
  data datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id_reply)
) TYPE=MyISAM;

CREATE TABLE topic (
  id_topic int(50) unsigned NOT NULL auto_increment,
  id_user int(50) unsigned NOT NULL default '0',
  titlu text NOT NULL,
  data datetime NOT NULL default '0000-00-00 00:00:00',
  lastpost datetime NOT NULL default '0000-00-00 00:00:00',
  descriere text NOT NULL,
  PRIMARY KEY  (id_topic)
) TYPE=MyISAM;

CREATE TABLE useri (
  id_user int(50) unsigned NOT NULL auto_increment,
  nume text NOT NULL,
  parola text NOT NULL,
  numeprenume text NOT NULL,
  mail text NOT NULL,
  PRIMARY KEY  (id_user)
) TYPE=MyISAM;

CREATE TABLE priv_mesg (
  id_msg int(50) unsigned NOT NULL auto_increment,
  id_sender int(50) unsigned NOT NULL,
  id_receiver int(50) unsigned NOT NULL,
  senddate datetime NOT NULL,
  contents text NOT NULL,
  PRIMARY KEY (id_msg)
) TYPE=MyISAM;


CREATE PROCEDURE simpleproc (IN my_user_id INT, OUT nrmsg INT)
BEGIN
	SELECT COUNT(*) INTO nrmsg
	FROM priv_mesg
	WHERE id_receiver = my_user_id;
END;
